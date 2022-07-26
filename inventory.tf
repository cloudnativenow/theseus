//  Collect together all of the output variables needed to build to the final
//  inventory from the inventory template

resource "local_file" "inventory" {
 content = templatefile("inventory.template.cfg", {
    control-public_ip = azurerm_linux_virtual_machine.theseus-vm.public_ip_address
  }
 )
 filename = "inventory-${azurerm_resource_group.rg.name}.cfg"
}

