
Muhammad Adistya Azhar
05111640000103

----------------------
# Implementasi Multi Master Group Replica
1. Desain dan implementasi infrastruktur
Arsitektur terdiri dari 3 database server, 1 database load balancer, 1 web server, dan 1 reverse proxy. Kotak merah menandakan berada dalam 1 vagrant machine.

![Desain infrastruktur](media/desain_infrastruktur.png )


----------------------------------

**Desain Infrastruktur Basis Data Terdistribusi & Load Balancing**

a. Database Server
   - Database 1
     - RAM: 512 MB
     - OS: Ubuntu 16.04
     - IP: 192.168.16.103
   - Database 2
     - RAM: 512 MB
     - OS: Ubuntu 16.04
     - IP: 192.168.16.104
   - Database 3
     - RAM: 512 MB
     - OS: Ubuntu 16.04
     - IP: 192.168.16.105

b. Database Load Balancer
- ProxySQL:
  - RAM: 512 MB
  - OS: Ubuntu 16.04
  - 192.168.16.107

c. Web Server & Reverse Proxy
  - Kestrel & Nginx
    - RAM: 1024 MB
    - OS: Ubuntu 16.04
    - 192.168.16.106