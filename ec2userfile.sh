#!/bin/bash
sleep 60
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1> hello world: deployed via TF and working with Vlad.</h1>" >  /var/www/html/index.html
