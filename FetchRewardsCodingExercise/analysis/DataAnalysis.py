
import pandas as pd

# Load datasets (update paths as needed)
users_df = pd.read_json('users.json', lines=True)
receipts_df = pd.read_json('receipts.json', lines=True)
brands_df = pd.read_json('brands.json', lines=True)

# Function to check data types
def check_data_types(df):
    return df.dtypes.to_dict()

# Function to calculate missing value percentages
def missing_value_percentage(df):
    return (df.isnull().sum() / len(df) * 100).to_dict()

# Function to calculate duplicate records
def count_duplicates(df, unique_field):
    return df.duplicated(subset=[unique_field]).sum()

# Outlier detection for numerical columns
def outlier_detection(df, column):
    return {
        "max": df[column].max(),
        "median": df[column].median(),
        "75th_percentile": df[column].quantile(0.75),
        "outlier_ratio": df[column].max() / df[column].quantile(0.75) if df[column].quantile(0.75) > 0 else None
    }

# Function to check relationship integrity
def check_relationship_integrity(parent_df, child_df, parent_key, child_key):
    unlinked = child_df[~child_df[child_key].isin(parent_df[parent_key])]
    return len(unlinked), unlinked

# Users analysis
users_analysis = {
    "Data Types": check_data_types(users_df),
    "Missing Values": missing_value_percentage(users_df),
    "Duplicates": count_duplicates(users_df, '_id')
}

# Receipts analysis
receipts_analysis = {
    "Data Types": check_data_types(receipts_df),
    "Missing Values": missing_value_percentage(receipts_df),
    "Duplicates": count_duplicates(receipts_df, '_id'),
    "Outliers - Points Earned": outlier_detection(receipts_df, 'pointsEarned'),
    "Outliers - Purchased Item Count": outlier_detection(receipts_df, 'purchasedItemCount')
}

# Relationship integrity between Receipts and Users
unlinked_user_ids = receipts_df[~receipts_df['userId'].isin(users_df['_id'])]
unlinked_count = len(unlinked_user_ids)
unlinked_percentage = (unlinked_count / len(receipts_df)) * 100

# Brands analysis
brands_analysis = {
    "Data Types": check_data_types(brands_df),
    "Missing Values": missing_value_percentage(brands_df),
    "Duplicates": count_duplicates(brands_df, '_id')
}

# Summary of Analysis
print("Users Analysis:")
for key, value in users_analysis.items():
    print(f"{key}: {value}")

print("\nReceipts Analysis:")
for key, value in receipts_analysis.items():
    print(f"{key}: {value}")

print("\nRelationship Integrity Risks:")
print(f"Unlinked user IDs in Receipts: {unlinked_count} ({unlinked_percentage:.2f}%)")

print("\nBrands Analysis:")
for key, value in brands_analysis.items():
    print(f"{key}: {value}")

print("\nStructural Observations:")
print("  Nested fields like rewardsReceiptItemList require normalization for efficient querying.")
print("  topBrand, currently stored as a float, should be represented as a Boolean for clarity.")
