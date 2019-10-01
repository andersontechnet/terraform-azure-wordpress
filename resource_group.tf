resource "random_id" "randwp" {
  byte_length = 9
}

resource "random_id" "randarm" {
  byte_length = 9
}

resource "random_string" "mysql_login" {
  length  = 8
  special = false
  number  = false
  upper   = false
  lower   = true
}
locals {
  common_tags = {
    environment = "${var.environment}"
    project     = "${var.project}"
    owner       = "${var.owner}"
  }

  extra_tags = {
    support = "${var.support}"
  }
}
resource "azurerm_resource_group" "rgwp" {
  name     = "${var.website}.com"
  location = "${var.ARM_REGION}"
  tags     = "${merge(local.common_tags, local.extra_tags)}"
}

resource "azurerm_template_deployment" "website" {
  name                = "${var.website}"
  resource_group_name = "${azurerm_resource_group.rgwp.name}"
  depends_on          = ["module.mysql"]

  template_body = <<DEPLOY
{
   "$schema":"http://schema.management.azure.com/schemas/2014-04-01-preview/deploymentTemplate.json#",
   "contentVersion":"1.0.0.0",
   "parameters":{
      "siteName":{
         "type":"string",
         "defaultValue":"${var.website}"
      },
      "dbhost":{
        "type":"string",
        "defaultValue":"${var.db_server}"
      },
      "dbuser":{
        "type":"string",
        "defaultValue":"${module.mysql.administrator_login}"
      },
      "hostingPlanName":{
         "type":"string",
         "defaultValue":"${var.website}-plan"
      },
      "sku":{  
         "type":"string",
         "allowedValues":[  
            "Free",
            "Shared",
            "Basic",
            "Standard",
            "Premium"
         ],
         "defaultValue":"Standard"
      },
      "workerSize":{  
         "type":"string",
         "allowedValues":[  
            "0",
            "1",
            "2"
         ],
         "defaultValue":"1"
      },
      "dbServer":{  
         "type":"string",
         "defaultValue":"${var.db_server}.mysql.database.azure.com:3306"
      },
      "dbName":{  
         "type":"string",
         "defaultValue":"${var.db_name}"
      },
      "dbAdminPassword":{  
         "type":"string",
         "defaultValue":"${module.mysql.administrator_login_password}"
      }
   },
   "variables":{  
      "connectionString":"[concat('Database=', parameters('dbName'), ';Data Source=', parameters('dbServer'), ';User Id=',parameters('dbuser'),'@',parameters('dbhost'),';Password=', parameters('dbAdminPassword'))]",
      "repoUrl":"https://github.com/azureappserviceoss/wordpress-azure",
      "branch":"master",
      "workerSize":"[parameters('workerSize')]",
      "sku":"[parameters('sku')]",
      "hostingPlanName":"[parameters('hostingPlanName')]"
   },
   "resources":[  
      {  
         "apiVersion":"2014-06-01",
         "name":"[variables('hostingPlanName')]",
         "type":"Microsoft.Web/serverfarms",
         "location":"[resourceGroup().location]",
         "properties":{  
            "name":"[variables('hostingPlanName')]",
            "sku":"[variables('sku')]",
            "workerSize":"[variables('workerSize')]",
            "hostingEnvironment":"",
            "numberOfWorkers":0
         }
      },
      {  
         "apiVersion":"2015-02-01",
         "name":"[parameters('siteName')]",
         "type":"Microsoft.Web/sites",
         "location":"[resourceGroup().location]",
         "tags":{  
            "[concat('hidden-related:', '/subscriptions/', subscription().subscriptionId,'/resourcegroups/', resourceGroup().name, '/providers/Microsoft.Web/serverfarms/', variables('hostingPlanName'))]":"empty"
         },
         "dependsOn":[  
            "[concat('Microsoft.Web/serverfarms/', variables('hostingPlanName'))]"
         ],
         "properties":{  
            "name":"[parameters('siteName')]",
            "serverFarmId":"[concat('/subscriptions/', subscription().subscriptionId,'/resourcegroups/', resourceGroup().name, '/providers/Microsoft.Web/serverfarms/', variables('hostingPlanName'))]",
            "hostingEnvironment":""
         },
         "resources":[  
            {  
               "apiVersion":"2015-04-01",
               "name":"connectionstrings",
               "type":"config",
               "dependsOn":[  
                  "[concat('Microsoft.Web/Sites/', parameters('siteName'))]"
               ],
               "properties":{  
                  "defaultConnection":{  
                     "value":"[variables('connectionString')]",
                     "type":"MySQL"
                  }
               }
            },
            {
               "apiVersion":"2015-04-01",
               "name":"web",
               "type":"config",
               "dependsOn":[  
                  "[concat('Microsoft.Web/Sites/', parameters('siteName'))]"
               ],
               "properties":{  
                  "phpVersion":"7.3"
               }
            },
            {  
               "apiVersion":"2015-08-01",
               "name":"web",
               "type":"sourcecontrols",
               "dependsOn":[  
                  "[resourceId('Microsoft.Web/Sites', parameters('siteName'))]",
                  "[concat('Microsoft.Web/Sites/', parameters('siteName'), '/config/connectionstrings')]",
                  "[concat('Microsoft.Web/Sites/', parameters('siteName'), '/config/web')]"
               ],
               "properties":{  
                  "RepoUrl":"[variables('repoUrl')]",
                  "branch":"[variables('branch')]",
                  "IsManualIntegration":true
               }
            }
         ]
      }      
   ],
     "outputs":{
    "fqdn":{
      "type":"string",
      "value" : "[concat('https://', parameters('siteName'), '.azurewebsites.net')]"
    }
  }
}
 DEPLOY

  deployment_mode = "Incremental"
}