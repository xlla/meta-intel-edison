#!/bin/bash                                                         
### This script should run only with the Edison in gadget mode      
### Check this with `lsusb` returns error                           
set -euf -o pipefail                                                
                                                                    
readonly GADGET_BASE_DIR="/sys/kernel/config/usb_gadget/g1"         
readonly DEV_ETH_ADDR="aa:bb:cc:dd:ee:f1"                           
readonly HOST_ETH_ADDR="aa:bb:cc:dd:ee:f2"                          
readonly USBDISK="/dev/mmcblk0p9"                                   
readonly SERIAL_TYPE="acm"                                          
#readonly SERIAL_TYPE="gser"                                        
#readonly NET_TYPE="eem"                                            
readonly NET_TYPE="rndis"                                           
                                                                    
# Check if already run before                                       
if [ -d "${GADGET_BASE_DIR}" ]; then                                
    echo "Already registered gadgets"                               
    exit 0                                                          
fi                                                                  
                                                                    
modprobe libcomposite                                               
                                                                    
# Create directory structure                                        
mkdir "${GADGET_BASE_DIR}"                                          
cd "${GADGET_BASE_DIR}"                                             
mkdir -p configs/c.1/strings/0x409                                  
mkdir -p strings/0x409                                              
                                                                    
# Serial device                                                     
### original example had `mkdir functions/acm.usb0`                 
### to make this work do on host as root:                           
### `echo 0x1d6b 0x0104 >/sys/bus/usb-serial/drivers/generic/new_id`
### this creates a new /dev/USBx port                               
### on Edison put a tty on the port with:                           
### `/sbin/agetty -L 115200 ttyGS0 xterm-256color`                  
mkdir "functions/${SERIAL_TYPE}.usb0"                               
ln -s "functions/${SERIAL_TYPE}.usb0" configs/c.1/                  
                                                                    
###                                                                 
                                                                    
# Ethernet device                                                   
###                                                                 
mkdir "functions/${NET_TYPE}.usb0"                                  
echo "${DEV_ETH_ADDR}" > "functions/${NET_TYPE}.usb0/dev_addr"      
echo "${HOST_ETH_ADDR}" > "functions/${NET_TYPE}.usb0/host_addr"    
ln -s "functions/${NET_TYPE}.usb0" configs/c.1/                     
###                                                                 
                                                                    
# Mass Storage device                                               
###                                                                 
mkdir functions/mass_storage.usb0                                   
echo 1 > functions/mass_storage.usb0/stall                          
echo 0 > functions/mass_storage.usb0/lun.0/cdrom                    
echo 0 > functions/mass_storage.usb0/lun.0/ro                       
echo 0 > functions/mass_storage.usb0/lun.0/nofua                    
echo "${USBDISK}" > functions/mass_storage.usb0/lun.0/file          
ln -s functions/mass_storage.usb0 configs/c.1/                      
###                                                                 
                                                                    
# Composite Gadget Setup                                            
echo 0x8087 > idVendor # Linux Foundation                           
echo 0x0a9e > idProduct # Multifunction Composite Gadget            
echo 0x0310 > bcdDevice # v1.0.0                                    
echo 0x0200 > bcdUSB # USB2                                         
echo "8452e52a5b73f5f38c917327f40a577c" > strings/0x409/serialnumber
echo "Intel Corporation" > strings/0x409/manufacturer               
echo "Edison" > strings/0x409/product                      
echo "mass rndis acm" > configs/c.1/strings/0x409/configuration     
echo 120 > configs/c.1/MaxPower                                     
                                                                    
# Activate gadgets                                                  
echo dwc3.0.auto > UDC                                              
sleep 1                                                             
ip link set dev usb0 up       
