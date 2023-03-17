# Customer Managed Key in Azure Data Factory using Terraform
This repo demos how to initially setup customer managed keys inside Azure Data Factory using Terraform. 
Data Factory is configured to connect with a GitHub repository to allow code collaboration.

The most important aspects are the following:
- The data factory instance must be empty when configuring CMK [[1](https://learn.microsoft.com/en-us/azure/data-factory/enable-customer-managed-key#enable-customer-managed-keys)]. This means there mustn't ne anything in the _live_ environment, while
the connection to a Git repository is not a problem
- You need a user-assigned identity to have access to the CMK in key vault [[2](https://learn.microsoft.com/en-us/azure/data-factory/enable-customer-managed-key#during-factory-creation-in-azure-portal)]. This is, because the identity must exist before the data factory
instance. The system-managed identity is bound to the lifecycle of the resource and thus exists _with_ it, not _before_ it.
- You don't need any specific firewall rules in Azure Key Vault, if you are using the _trusted services_ flag as data factory is part of these
services [[3](https://learn.microsoft.com/en-us/azure/key-vault/general/overview-vnet-service-endpoints)]
- The key must be of type RSA [[4](https://learn.microsoft.com/en-us/azure/data-factory/enable-customer-managed-key#generate-or-upload-customer-managed-key-to-azure-key-vault)]