from azure.identity import DefaultAzureCredential
from azure.mgmt.storage import StorageManagementClient
import os

# Configuration - Replace with your actual details
subscription_id = "4a59fbed-2876-4e34-bf57-0ccec60fdef1"
resource_group_name = "example-resources"
storage_account_name = "examplestoragetf"

def audit_storage_account():
    # Authenticate using the session you already have via 'az login'
    credential = DefaultAzureCredential()
    storage_client = StorageManagementClient(credential, subscription_id)

    # Fetch the storage account properties
    account = storage_client.storage_accounts.get_properties(
        resource_group_name, 
        storage_account_name
    )

    # Check compliance for Blob public access
    is_public_access_enabled = account.allow_blob_public_access
    
    print(f"Storage Account: {storage_account_name}")
    print(f"Allow Blob Public Access: {is_public_access_enabled}")

    if is_public_access_enabled:
        print("[!] COMPLIANCE ALERT: Public access is ENABLED.")
    else:
        print("[+] COMPLIANCE PASSED: Public access is DISABLED.")

if __name__ == "__main__":
    audit_storage_account()
