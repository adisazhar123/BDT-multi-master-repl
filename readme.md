
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


**Implementasi infrastruktur basis data terdistribusi**

a. Proses instalasi *database server*
Database yang digunakan adalah MySQL dengan plugin MySQL Group replication. Berikut adalah step yang harus dilakukan:

  1. Download MySQL Server dan MySQL Client binary (dilakukan di ketiga DB server)
      `curl -OL https://dev.mysql.com/get/Downloads MySQL-5.7mysql-common_5.7.23-1ubuntu16.04_amd64.deb`
      `curl -OL https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-community-client_5.7.23-1ubuntu16.04_amd64.deb`
      `curl -OL https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-client_5.7.23-1ubuntu16.04_amd64.deb`
      `curl -OL https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-community-server_5.7.23-1ubuntu16.04_amd64.deb`
  2. Set default MySQL password agar tidak perlu input manual saat instalasi (dilakukan di ketiga DB server)
      `sudo debconf-set-selections <<< 'mysql-community-server mysql-community-server/root-pass password admin'`
      `sudo debconf-set-selections <<< 'mysql-community-server mysql-community-server/re-root-pass password admin'`
  3. Run .deb file yang telah didownload pada step 1 (dilakukan di ketiga DB server):
      `sudo dpkg -i mysql-common_5.7.23-1ubuntu16.04_amd64.deb`
      `sudo dpkg -i mysql-community-client_5.7.23-1ubuntu16.04_amd64.deb`
      `sudo dpkg -i mysql-client_5.7.23-1ubuntu16.04_amd64.deb`
      `sudo dpkg -i mysql-community-server_5.7.23-1ubuntu16.04_amd64.deb`
  4. MySQL berkomunikasi menggunakan port 33061 dan 3306, maka kita harus membuka port tersebut (dilakukan di ketiga DB server):
      `sudo ufw allow 33061`
      `sudo ufw allow 3306`
  5. Setiap MySQL server membutuhkan file konfigurasi `my.cnf`. Agar group replication dapat berjalan, kita harus set beberapa variable. 
  Database server yang akan kita buat memiliki IP sebagai berikut: `192.168.16.103`, `192.168.16.104`, dan `192.168.16.105`. Ketiga nya akan berada dalam 1 group, dan berperan sebagai `write` dan `read`. Setiap group memiliki *identifier* yang unik, dan harus kita definisikan sendiri. Linux memiliki command `uuidgen` untuk membuat UUID. Output dari `uuidgen` akan digunakan untuk set variable `loose-group_replication_group_name="8f22f846-9922-4139-b2b7-097d185a93cb"`. Setelah set `loose-group_replication_group_name` kita harus menambahkan IP DB server ke dalam whitelist untuk menentukan IP mana saja yang boleh *connect* ke group. Parameter tersebut adalah `loose-group_replication_ip_whitelist="192.168.16.103, 192.168.16.104, 192.168.16.105"`. Ketiga member tersebut akan memberi data jika ada member yang baru join, maka agar pemberian data dapat terjadi, parameter `loose-group_replication_group_seeds` terisi menjadi `loose-group_replication_group_seeds = "192.168.16.103:33061, 192.168.16.104:33061, 192.168.16.105:33061"`.
  Agar *multi primary mode* nyala, kita harus mematikan *single primary mode* dengan cara ```loose-group_replication_single_primary_mode = OFF```.
  Setiap DB Server memiliki *host specific* konfigurasi, parameter berikut hanya berlaku dengan IP server dimana DB berjalan:
  ```
    bind-address = "192.168.16.103"
    report_host = "192.168.16.103"
    loose-group_replication_local_address = "192.168.16.103:33061"
  ```
  Berikut adalah contoh file `my.cnf`.

  ```
    !includedir /etc/mysql/conf.d/
    !includedir /etc/mysql/mysql.conf.d/
    [mysqld]

    # General replication settings
    gtid_mode = ON
    enforce_gtid_consistency = ON
    master_info_repository = TABLE
    relay_log_info_repository = TABLE
    binlog_checksum = NONE
    log_slave_updates = ON
    log_bin = binlog
    binlog_format = ROW
    transaction_write_set_extraction = XXHASH64
    loose-group_replication_bootstrap_group = OFF
    loose-group_replication_start_on_boot = OFF
    loose-group_replication_ssl_mode = REQUIRED
    loose-group_replication_recovery_use_ssl = 1

    # Shared replication group configuration
    loose-group_replication_group_name = "8f22f846-9922-4139-b2b7-097d185a93cb"
    loose-group_replication_ip_whitelist = "192.168.16.103, 192.168.16.104, 192.168.16.105"
    loose-group_replication_group_seeds = "192.168.16.103:33061, 192.168.16.104:33061, 192.168.16.105:33061"

    # Single or Multi-primary mode? Uncomment these two lines
    # for multi-primary mode, where any host can accept writes
    loose-group_replication_single_primary_mode = OFF
    loose-group_replication_enforce_update_everywhere_checks = ON

    # Host specific replication configuration
    server_id = 103
    bind-address = "192.168.16.103"
    report_host = "192.168.16.103"
    loose-group_replication_local_address = "192.168.16.103:33061"
  ```
  6. Restart MySQL Server
   `sudo systemctl restart mysql`
  7. Buat MySQL User khusus untuk proses replikasi, dan install `Group Replication Plugin`
  (dilakukan di ketiga DB server).
   ```
    mysql -u root -p
  ```
  ```
    msql> SET SQL_LOG_BIN=0;
    msql> CREATE USER 'repl'@'%' IDENTIFIED BY 'password' REQUIRE SSL;
    msql> GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
    msql> FLUSH PRIVILEGES;
    msql> SET SQL_LOG_BIN=1;
   ```
   ```
  CHANGE MASTER TO MASTER_USER='repl', MASTER_PASSWORD='password' FOR CHANNEL 'group_replication_recovery';
   ```
   ```
  INSTALL PLUGIN group_replication SONAME 'group_replication.so';
   ```
  8. Mulai group replication. Ketika belum ada member yang belum join group, maka harus dilakukan step khusus. Harus dilakukan ini karena member akan bergantung pada member lain untuk mendapatkan data. Oleh karena itu, untuk member pertama yang join group, kita akan set agar tidak mengharapkan data. (Hanya dilakukan di salah 1 member)
  ```
  (192.168.16.103) mysql> SET GLOBAL group_replication_bootstrap_group=ON;
  (192.168.16.103) mysql> START GROUP_REPLICATION;
  (192.168.16.103) mysql> SET GLOBAL group_replication_bootstrap_group=OFF;
  ```
  Cek member sudah masuk grup:
  ```
  (192.168.16.103) mysql> SELECT * FROM performance_schema.replication_group_members;
  ```
  9. Join group untuk member yang lain dengan cara:
  ```
  (192.168.16.104) mysql> START GROUP_REPLICATION;
  ```
  ```
  (192.168.16.105) mysql> START GROUP_REPLICATION;
  ```
  Cek bahwa seluruh member sudah join group:
  ```
  (192.168.16.105) mysql> SELECT * FROM performance_schema.replication_group_members;
  ```

b. Proses instalasi *database load balancer* ProxySQL