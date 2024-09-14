# show_nat_clients.sh
Shows the active NAT clients on a Linux router, inluding OpenWRT, and with enhanced support for GL.iNet routers.

# Example usage
~~~
root@ubuntu:# ./show_nat_clients.sh
IP Address	MAC Address		DNS Name
----------	-----------		--------
10.10.10.100	88:dc:96:64:b1:2e 	engenius-ap-wifi.localdomain
10.10.10.109	34:5e:08:6f:46:6a 	roku-mbr.localdomain
10.10.10.62	ec:f4:bb:26:17:1c 	delle7240-lan.localdomain
10.10.10.75	ac:ae:19:0d:7e:5a 	roku-living-room.localdomain
10.10.10.76	24:29:34:81:ad:48 	lesterpixel.localdomain
10.10.10.85	08:00:27:1c:5a:7f 	win10vm.localdomain
10.10.10.86	f8:5b:3b:e6:d2:44 	vzwextender4g.localdomain
10.99.1.31	8c:49:62:bb:30:18 	RokuPatio ** (Roku, Inc)
10.99.1.7	48:c7:96:7d:5f:a3 	-NA- ** (Samsung Electronics Co.,Ltd)
~~~
~~~
root@GL-A1300:# ./show_nat_clients.sh 
IP Address	MAC Address		DNS Name
----------	-----------		--------
192.168.8.123	a6:fd:85:c7:04:1c*	Pixel-6a.lan
192.168.8.156	04:f7:78:17:9a:3c 	ps5-wifi **
192.168.8.212	c0:74:ad:a9:94:2e 	1-voip-ata **
192.168.8.248	bc:03:58:da:bd:08 	YOGA9_PF4MQ095.lan
~~~
