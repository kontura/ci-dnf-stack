Feature: DNF/Behave test (install remove test)

Scenario: Install TestA from repository "test-1"
 Given I use the repository "test-1"
 When I execute "dnf" command "install -y TestA" with "success"
 Then package "TestA, TestB" should be "installed"
 And package "TestC" should be "absent"
 When I "install" a package "TestA" with "dnf"
 Then package "TestA, TestB" should be "present"
 When I "remove" a package "TestA" with "dnf"
 Then package "TestA, TestB" should be "removed"
 And package "TestC" should be "absent"

 When I "install" a package "TestD" with "dnf"
 Then package "TestD, TestE" should be "installed"
 When I "remove" a package "TestD" with "dnf"
 Then package "TestD, TestE" should be "removed"

 When I "install" a package "TestF" with "dnf"
 Then package "TestF, TestG, TestH" should be "installed"
 When I "remove" a package "TestF" with "dnf"
 Then package "TestF, TestG, TestH" should be "removed"

 When I execute "dnf" command "install -y TestI" with "fail"
 Then package "TestI, TestJ" should be "absent"

 When I "install" a package "TestK, TestL" with "dnf"
 Then package "TestK, TestL, TestM" should be "installed"
 When I "remove" a package "TestK" with "dnf"
 Then package "TestK" should be "removed"
 And package "TestL, TestM" should be "present"
 And package "TestL, TestM" should be "unupgraded"
 When I "remove" a package "TestL" with "dnf"
 Then package "TestL, TestM" should be "removed"

 When I execute "dnf" command "install -y ProvideA" with "success"
 Then package "TestO, TestC" should be "installed"
 When I execute "dnf" command "remove -y ProvideA" with "success"
 Then package "TestO, TestC" should be "removed"

 When I execute "dnf" command "install -y http://127.0.0.1/repo/test-1/TestB-1.0.0-1.noarch.rpm" with "success"
 Then package "TestB" should be "installed"
 When I execute "dnf" command "remove -y TestB" with "success"
 Then package "TestB" should be "removed"

 When I execute "dnf" command "install -y /var/www/html/repo/test-1/TestB-1.0.0-1.noarch.rpm" with "success"
 Then package "TestB" should be "installed"
 When I execute "dnf" command "remove -y TestB" with "success"
 Then package "TestB" should be "removed"

 When I execute "bash" command "mkdir /test" with "success"
 When I execute "bash" command "cp /var/www/html/repo/test-1/Test{A,B,C}*.rpm /test" with "success"
 When I execute "dnf" command "install -y /test/*.rpm" with "success"
 Then package "TestA, TestB, TestC" should be "installed"
 When I execute "dnf" command "remove -y TestA TestB TestC" with "success"
 Then package "TestA, TestB, TestC" should be "removed"

 When I execute "dnf" command "group list Testgroup" with "success"
 Then line from "stdout" should "not start" with "Installed groups:"
 And line from "stdout" should "start" with "Available groups:"
 When I execute "dnf" command "install -y @Testgroup" with "success"
 Then package "TestA, TestB, TestC" should be "installed"
 When I execute "dnf" command "group list Testgroup" with "success"
 Then line from "stdout" should "start" with "Installed groups:"
 And line from "stdout" should "not start" with "Available groups:"
 When I execute "dnf" command "install -y TestD" with "success"
 Then package "TestD, TestE" should be "installed"
 When I execute "dnf" command "group remove -y Testgroup" with "success"
 Then package "TestA, TestB, TestC" should be "removed"
 When I execute "dnf" command "group list Testgroup" with "success"
 Then line from "stdout" should "not start" with "Installed groups:"
 And line from "stdout" should "start" with "Available groups:"
 When I execute "dnf" command "remove -y TestD, TestE" with "success"
 Then package "TestD, TestE" should be "removed"

 When I execute "dnf" command "group list Testgroup" with "success"
 Then line from "stdout" should "not start" with "Installed groups:"
 And line from "stdout" should "start" with "Available groups:"
 When I execute "dnf" command "group install -y with-optional Testgroup" with "success"
 Then package "TestA, TestB, TestC, TestD, TestE" should be "installed"
 When I execute "dnf" command "group list Testgroup" with "success"
 Then line from "stdout" should "start" with "Installed groups:"
 And line from "stdout" should "not start" with "Available groups:"
 When I execute "dnf" command "remove -y @Testgroup" with "success"
 Then package "TestA, TestB, TestC, TestD, TestE" should be "removed"
 When I execute "dnf" command "group list Testgroup" with "success"
 Then line from "stdout" should "not start" with "Installed groups:"
 And line from "stdout" should "start" with "Available groups:"

 When I execute "dnf" command "group list Testgroup" with "success"
 Then line from "stdout" should "not start" with "Installed groups:"
 And line from "stdout" should "start" with "Available groups:"
 When I execute "dnf" command "install -y TestA" with "success"
 Then package "TestA, TestB" should be "installed"
 When I execute "dnf" command "group list Testgroup" with "success"
 Then line from "stdout" should "not start" with "Installed groups:"
 And line from "stdout" should "start" with "Available groups:"
 When I execute "dnf" command "install -y @Testgroup" with "success"
 Then package "TestC" should be "installed"
 And package "TestA, TestB" should be "present"
 When I execute "dnf" command "group list Testgroup" with "success"
 Then line from "stdout" should "start" with "Installed groups:"
 And line from "stdout" should "not start" with "Available groups:"
 When I execute "dnf" command "group remove -y Testgroup" with "success"
 Then package "TestC" should be "removed"
 And package "TestA, TestB" should be "present"
 When I execute "dnf" command "group list Testgroup" with "success"
 Then line from "stdout" should "not start" with "Installed groups:"
 And line from "stdout" should "start" with "Available groups:"
 When I execute "dnf" command "remove -y TestA" with "success"
 Then package "TestA, TestB" should be "removed"

 When I execute "dnf" command "group list Testgroup" with "success"
 Then line from "stdout" should "not start" with "Installed groups:"
 And line from "stdout" should "start" with "Available groups:"
 When I execute "dnf" command "install -y TestC" with "success"
 Then package "TestC" should be "installed"
 When I execute "dnf" command "group list Testgroup" with "success"
 Then line from "stdout" should "not start" with "Installed groups:"
 And line from "stdout" should "start" with "Available groups:"
 When I execute "dnf" command "install -y @Testgroup" with "success"
 Then package "TestA, TestB" should be "installed"
 And package "TestC" should be "present"
 When I execute "dnf" command "group list Testgroup" with "success"
 Then line from "stdout" should "start" with "Installed groups:"
 And line from "stdout" should "not start" with "Available groups:"
 When I execute "dnf" command "group remove -y Testgroup" with "success"
 Then package "TestA, TestB" should be "removed"
 When I execute "dnf" command "group list Testgroup" with "success"
 Then line from "stdout" should "not start" with "Installed groups:"
 And line from "stdout" should "start" with "Available groups:"
 When I execute "dnf" command "remove -y TestC" with "success"
 Then package "TestC" should be "removed"
