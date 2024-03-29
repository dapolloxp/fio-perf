data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "azurerm_storage_account" "storage_account" {

  name                      = format("%s%s", var.storageaccountnameprefix, random_string.random.result)
  resource_group_name       = azurerm_resource_group.aks-rg.name
  location                  = azurerm_resource_group.aks-rg.location
  account_tier              = var.account_tier
  account_kind              = var.account_kind
  account_replication_type  = "LRS"
  enable_https_traffic_only = false
  network_rules {
    bypass         = ["AzureServices"]
    default_action = "Deny"
    ip_rules = [
      "${chomp(data.http.myip.body)}"
    ]
    virtual_network_subnet_ids = [azurerm_subnet.akssubnet.id]
  }
  share_properties {
    smb {
      multichannel_enabled = true
    }
  }
}

resource "azurerm_storage_share" "azurefileshare" {
  name                 = "fileshare01"
  quota                = 102400
  storage_account_name = azurerm_storage_account.storage_account.name
  enabled_protocol     = var.nfs_share_enabled ? "NFS" : "SMB"
}

resource "azurerm_monitor_diagnostic_setting" "storage_diag" {
  name                       = "storage_diag-${random_string.random.result}"
  target_resource_id         = "${azurerm_storage_account.storage_account.id}/fileServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law_c.id

  log {
    category = "StorageRead"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "StorageWrite"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "StorageDelete"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }


  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}