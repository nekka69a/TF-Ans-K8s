output "Ctlplane_Pub_Ip" {
  value = module.vms.The_webserver_Public_ip_cltplane
}

output "Ctlplane_private_Ip" {
  value = module.vms.The_webserver_Private_ip_ctlplane
}

output "Size_of_VMS" {
  value = module.vms.VM_Size
}

output "Worker1_Pub_Ip" {
  value = module.vms.The_webserver_Public_ip_worker1
}

output "Worker1_private_Ip" {
  value = module.vms.The_webserver_Private_ip_worker2
}

output "Worker2_Pub_Ip" {
  value = module.vms.The_webserver_Public_ip_worker2
}

output "Worker2_private_Ip" {
  value = module.vms.The_webserver_Private_ip_worker2
}

output "pubkeyctl" {
  value     = module.vms.pubsshctl
  sensitive = true
}

output "private_keyctl" {
    value   = module.vms.pvtsshctl
    sensitive = true
}

output "pub_keywks" {
  value     = module.vms.pubwks
  sensitive = true
}

output "private_keywks" {
    value   = module.vms.privatewks
    sensitive = true
}
