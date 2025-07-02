Feature: zchunk tests


Scenario: I can install an RPM from local mirror with zchunk repo and enabled zchunk
Given I copy repository "simple-base" for modification
  And I generate repodata for repository "simple-base" with extra arguments "--zck"
  And I use repository "simple-base"
  And I configure dnf with
      | key    | value |
      | zchunk | True  |
 When I execute dnf with args "install labirinto"
 Then the exit code is 0
  And Transaction is following
      | Action        | Package                       |
      | install       | labirinto-0:1.0-1.fc29.x86_64 |


Scenario: download zchunk metadata, enabled by default
Given I copy repository "simple-base" for modification
  And I generate repodata for repository "simple-base" with extra arguments "--zck"
  And I use repository "simple-base" as http
  And I start capturing outbound HTTP requests
 When I execute dnf with args "install labirinto"
 Then the exit code is 0
  And exactly 2 HTTP GET requests should match:
      | path                      |
      | /repodata/primary.xml.zck |


@bz1851841
@bz1779104
Scenario: ignore zchunk metadata if disabled
Given I copy repository "simple-base" for modification
  And I generate repodata for repository "simple-base" with extra arguments "--zck"
  And I use repository "simple-base" as http
  And I start capturing outbound HTTP requests
  And I configure dnf with
      | key    | value |
      | zchunk | False |
 When I execute dnf with args "install labirinto"
 Then the exit code is 0
  And exactly 1 HTTP GET requests should match:
      | path                      |
      | /repodata/primary.xml.zst |


@bz1886706
Scenario: I can install an RPM from FTP mirror with zchunk repo and enabled zchunk
Given I copy repository "simple-base" for modification
  And I generate repodata for repository "simple-base" with extra arguments "--zck"
  And I use repository "simple-base" as ftp
  And I configure dnf with
      | key    | value |
      | zchunk | True  |
 When I execute dnf with args "install labirinto"
 Then the exit code is 0
  And Transaction is following
      | Action        | Package                       |
      | install       | labirinto-0:1.0-1.fc29.x86_64 |


Scenario: I can install an RPM from FTP mirror with zchunk repo and disabled zchunk
Given I copy repository "simple-base" for modification
  And I generate repodata for repository "simple-base" with extra arguments "--zck"
  And I use repository "simple-base" as ftp
  And I configure dnf with
      | key    | value |
      | zchunk | False |
 When I execute dnf with args "install labirinto"
 Then the exit code is 0
  And Transaction is following
      | Action        | Package                       |
      | install       | labirinto-0:1.0-1.fc29.x86_64 |


Scenario: when zchunk is enabled, prefer HTTP over FTP
Given I copy repository "simple-base" for modification
  And I generate repodata for repository "simple-base" with extra arguments "--zck"
  And I start http server "http_server" at "/{context.dnf.repos[simple-base].path}"
  And I start ftp server "ftp_server" at "/{context.dnf.repos[simple-base].path}"
  And I create and substitute file "/tmp/mirrorlist" with
      """
      ftp://localhost:{context.dnf.ports[ftp_server]}/
      http://localhost:{context.dnf.ports[http_server]}/
      """
  And I configure a new repository "testrepo" with
      | key        | value                                    |
      | mirrorlist | {context.dnf.installroot}/tmp/mirrorlist |
  And I configure dnf with
      | key    | value |
      | zchunk | True  |
  And I start capturing outbound HTTP requests
 When I execute dnf with args "install labirinto"
 Then the exit code is 0
  And Transaction is following
      | Action        | Package                       |
      | install       | labirinto-0:1.0-1.fc29.x86_64 |
  And exactly 2 HTTP GET requests should match:
      | path                      |
      | /repodata/primary.xml.zck |


Scenario: when zchunk is enabled, prefer HTTP over FTP (reversed)
Given I copy repository "simple-base" for modification
  And I generate repodata for repository "simple-base" with extra arguments "--zck"
  And I start http server "http_server" at "/{context.dnf.repos[simple-base].path}"
  And I start ftp server "ftp_server" at "/{context.dnf.repos[simple-base].path}"
  And I create and substitute file "/tmp/mirrorlist" with
      """
      http://localhost:{context.dnf.ports[http_server]}/
      ftp://localhost:{context.dnf.ports[ftp_server]}/
      """
  And I configure a new repository "testrepo" with
      | key        | value                                    |
      | mirrorlist | {context.dnf.installroot}/tmp/mirrorlist |
  And I configure dnf with
      | key    | value |
      | zchunk | True  |
  And I start capturing outbound HTTP requests
 When I execute dnf with args "install labirinto"
 Then the exit code is 0
  And Transaction is following
      | Action        | Package                       |
      | install       | labirinto-0:1.0-1.fc29.x86_64 |
  And exactly 2 HTTP GET requests should match:
      | path                      |
      | /repodata/primary.xml.zck |


Scenario: using mirror wihtout ranges supports and zchunk results in only two GET requests for primary (the first try is with range specified)
Given I copy repository "simple-base" for modification
  And I generate repodata for repository "simple-base" with extra arguments "--zck"
  And I use repository "simple-base" as http
  And I configure dnf with
      | key    | value |
      | zchunk | True |
  And I start capturing outbound HTTP requests
 When I execute dnf with args "install labirinto"
 Then the exit code is 0
  And Transaction is following
      | Action        | Package                       |
      | install       | labirinto-0:1.0-1.fc29.x86_64 |
  And exactly 2 HTTP GET requests should match:
      | path                      |
      | /repodata/primary.xml.zck |

  Scenario: using mirror wiht ranges support and zchunk
Given I copy repository "dnf-ci-fedora" for modification
  And I generate repodata for repository "dnf-ci-fedora" with extra arguments "--zck"
  And I create and substitute file "/{context.dnf.tempdir}/lighttpd.conf" with
      """
      server.document-root = "{context.dnf.repos[dnf-ci-fedora].path}"
      server.port = 8080

      server.modules += ( "mod_accesslog" )
      server.errorlog = "/{context.dnf.tempdir}/lighttpd_error.log"
      accesslog.filename = "/{context.dnf.tempdir}/lighttpd_access.log"
      accesslog.format = "%r Status code: %>s Sent: %b \"%{{Referer}}i\" --- Ranges: %{{Range}}i"
      """
  And I execute "lighttpd -f /{context.dnf.tempdir}/lighttpd.conf"
  And I configure dnf with
      | key    | value |
      | zchunk | True |
  And I use repository "dnf-ci-fedora" with configuration
      | key     | value                  |
      | baseurl | http://localhost:8080/ |
  And I successfully execute dnf with args "install wget"
  # Update the metadata with a small update (just one package)
  And I copy file "{context.dnf.fixturesdir}/repos/simple-base/x86_64/labirinto-1.0-1.fc29.x86_64.rpm" to "/{context.dnf.repos[dnf-ci-fedora].path}/x86_64/"
  And I generate repodata for repository "dnf-ci-fedora" with extra arguments "--zck"
  # This wait seems to be needed for lighttpd to notice the files have changed
  And I execute "sleep 5s"
 When I execute dnf with args "install labirinto --refresh"
 Then the exit code is 0
  And Transaction is following
      | Action        | Package                       |
      | install       | labirinto-0:1.0-1.fc29.x86_64 |
  And I execute "pkill lighttpd"
  And file "/{context.dnf.tempdir}/lighttpd_access.log" contents is
      """
      GET /repodata/repomd.xml HTTP/1.1 Status code: 200 Sent: 3020 "-" --- Ranges: -
      GET /repodata/primary.xml.zck HTTP/1.1 Status code: 206 Sent: 882 "-" --- Ranges: bytes=0-881
      GET /repodata/primary.xml.zck HTTP/1.1 Status code: 206 Sent: 73853 "-" --- Ranges: bytes=882-74734
      GET /x86_64/wget-1.19.5-5.fc29.x86_64.rpm HTTP/1.1 Status code: 200 Sent: 7226 "-" --- Ranges: -
      GET /repodata/repomd.xml HTTP/1.1 Status code: 200 Sent: 3020 "-" --- Ranges: -
      GET /repodata/primary.xml.zck HTTP/1.1 Status code: 206 Sent: 902 "-" --- Ranges: bytes=0-901
      GET /repodata/primary.xml.zck HTTP/1.1 Status code: 206 Sent: 856 "-" --- Ranges: bytes=902-1020,57128-57646
      GET /x86_64/labirinto-1.0-1.fc29.x86_64.rpm HTTP/1.1 Status code: 200 Sent: 6186 "-" --- Ranges: -
      """
