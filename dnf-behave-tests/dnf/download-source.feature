Feature: Tests for different package download sources


@bz1775184
Scenario: baseurl is used if all mirrors from mirrorlist fail
Given I create directory "/baseurlrepo"
  And I execute "createrepo_c {context.dnf.installroot}/baseurlrepo"
  And I create file "/tmp/mirrorlist" with
      """
      file:///nonexistent.repo
      http://127.0.0.1:5000/nonexistent
      """
  And I configure a new repository "testrepo" with
      | key        | value                                    |
      | baseurl    | {context.dnf.installroot}/baseurlrepo    |
      | mirrorlist | {context.dnf.installroot}/tmp/mirrorlist |
 When I execute dnf with args "makecache"
 Then the exit code is 0
  And stderr is empty


@bz1775184
Scenario: baseurl is used if mirrorlist file cannot be found
Given I create directory "/baseurlrepo"
  And I execute "createrepo_c {context.dnf.installroot}/baseurlrepo"
  And I configure a new repository "testrepo" with
      | key        | value                                    |
      | baseurl    | {context.dnf.installroot}/baseurlrepo    |
      | mirrorlist | {context.dnf.installroot}/tmp/mirrorlist |
 When I execute dnf with args "makecache"
 Then the exit code is 0
  And stderr is empty


@bz1775184
Scenario: baseurl is used if mirrorlist file is empty
Given I create directory "/baseurlrepo"
  And I execute "createrepo_c {context.dnf.installroot}/baseurlrepo"
  And I create file "/tmp/mirrorlist" with
      """
      """
  And I configure a new repository "testrepo" with
      | key        | value                                    |
      | baseurl    | {context.dnf.installroot}/baseurlrepo    |
      | mirrorlist | {context.dnf.installroot}/tmp/mirrorlist |
 When I execute dnf with args "makecache"
 Then the exit code is 0
  And stderr is empty


Scenario: no working donwload source result in an error
Given I create directory "/baseurlrepo"
  And I execute "createrepo_c {context.dnf.installroot}/baseurlrepo"
  And I create file "/tmp/mirrorlist" with
      """
      file:///nonexistent.repo
      http://127.0.0.1:5000/nonexistent
      """
  And I configure a new repository "testrepo" with
      | key        | value                                    |
      | baseurl    | {context.dnf.installroot}/I_dont_exist   |
      | mirrorlist | {context.dnf.installroot}/tmp/mirrorlist |
 When I execute dnf with args "makecache"
 Then the exit code is 1
  And stderr contains "Errors during downloading metadata for repository 'testrepo':"
  And stderr contains "- Curl error \(37\): Couldn't read a file:// file for file:///nonexistent.repo/repodata/repomd.xml \[Couldn't open file /nonexistent.repo/repodata/repomd.xml\]"
  And stderr contains "- Curl error \(7\): Couldn't connect to server for http://127.0.0.1:5000/nonexistent/repodata/repomd.xml \[Failed to connect to 127.0.0.1 port 5000: Connection refused\]"
  And stderr contains "- Curl error \(37\): Couldn't read a file:// file for file:///tmp/dnf_ci_installroot_.*/I_dont_exist/repodata/repomd.xml \[Couldn't open file /tmp/dnf_ci_installroot_.*/I_dont_exist/repodata/repomd.xml\]"
  And stderr contains "Error: Failed to download metadata for repo 'testrepo': Cannot download repomd.xml: Cannot download repodata/repomd.xml: All mirrors were tried"


Scenario: mirrorlist is prefered over baseurl
Given I create directory "/baseurlrepo"
  And I execute "createrepo_c {context.dnf.installroot}/baseurlrepo"
  And I create directory "/mirrorlistrepo"
  And I copy file "{context.dnf.fixturesdir}/repos/dnf-ci-fedora/noarch/setup-2.12.1-1.fc29.noarch.rpm" to "/mirrorlistrepo/setup-2.12.1-1.fc29.noarch.rpm"
  And I execute "createrepo_c {context.dnf.installroot}/mirrorlistrepo"
  And I create and substitute file "/tmp/mirrorlist" with
      """
      file://{context.dnf.installroot}/mirrorlistrepo
      """
  And I configure a new repository "testrepo" with
      | key        | value                                    |
      | baseurl    | {context.dnf.installroot}/baseurlrepo    |
      | mirrorlist | {context.dnf.installroot}/tmp/mirrorlist |
 When I execute dnf with args "install setup"
 Then the exit code is 0
  And Transaction is following
      | Action        | Package                      |
      | install       | setup-0:2.12.1-1.fc29.noarch |


Scenario: Install from local repodata with locations pointing to remote packages
Given I make packages from repository "dnf-ci-fedora" accessible via http
  And I copy repository "dnf-ci-fedora" for modification
  And I generate repodata for repository "dnf-ci-fedora" with extra arguments "--location-prefix http://localhost:{context.dnf.ports[dnf-ci-fedora]}"
  And I use repository "dnf-ci-fedora"
  # delete packages from the repo copied for modification so they cannot be accidentally used
  And I delete directory "/{context.dnf.repos[dnf-ci-fedora].path}/noarch"
 When I execute dnf with args "--setopt=keepcache=true install setup"
 Then the exit code is 0
  And stderr is empty
  And Transaction is following
      | Action        | Package                                  |
      | install       | setup-0:2.12.1-1.fc29.noarch             |
  And file "/var/cache/dnf/dnf-ci-fedora*/packages/setup*" exists


Scenario: Install from remote repodata with locations pointing to packages on different HTTP servers
Given I make packages from repository "dnf-ci-fedora" accessible via http
  And I copy repository "dnf-ci-fedora" for modification
  And I generate repodata for repository "dnf-ci-fedora" with extra arguments "--location-prefix http://localhost:{context.dnf.ports[dnf-ci-fedora]}"
  And I use repository "dnf-ci-fedora" as http
  # delete packages from the repo copied for modification so they cannot be accidentally used
  And I delete directory "/{context.dnf.repos[dnf-ci-fedora].path}/noarch"
 When I execute dnf with args "install setup"
 Then the exit code is 0
  And stderr is empty
  And Transaction is following
      | Action        | Package                                  |
      | install       | setup-0:2.12.1-1.fc29.noarch             |


@bz1817130
Scenario: Download a package that contains special URL characters that need to be encoded (e.g. a +)
Given I use repository "download-sources" as http
  And I start capturing outbound HTTP requests
 When I execute dnf with args "install special-c++-package"
 Then the exit code is 0
  And HTTP log contains
      """
      GET /noarch/special-c%2b%2b-package-1.0-1.noarch.rpm
      """


@bz1817130
@xfail
# For packages with full URL in their location we can't encode the package name.
# The URL would need to come encoded in the repo metadata from createrepo_c.
Scenario: Download a package that contains special URL characters with full URL in location
Given I make packages from repository "download-sources" accessible via http
  And I copy repository "download-sources" for modification
  And I generate repodata for repository "download-sources" with extra arguments "--location-prefix http://localhost:{context.dnf.ports[download-sources]}"
  And I use repository "download-sources" as http
  # delete packages from the repo copied for modification so they cannot be accidentally used
  And I delete directory "/{context.dnf.repos[download-sources].path}/noarch"
  And I start capturing outbound HTTP requests
 When I execute dnf with args "install special-c++-package"
 Then the exit code is 0
  And HTTP log contains
      """
      GET /noarch/special-c%2b%2b-package-1.0-1.noarch.rpm
      """


@bz1966482
Scenario: when the first mirror from metalink isn't available we try the next one
Given I copy repository "simple-base" for modification
  And I copy directory "/{context.dnf.repos[simple-base].path}" to "/mirror"
  And I start http server "mirror" at "{context.dnf.installroot}/mirror"
  And I use repository "simple-base" as http
  And I set up metalink for repository "simple-base"
  And I add "http://localhost:{context.dnf.ports[mirror]}" mirror to "simple-base" metalink
  And I delete directory "/{context.dnf.repos[simple-base].path}/repodata"
  And I start capturing outbound HTTP requests
 When I execute dnf with args "makecache --refresh"
 Then the exit code is 0
  And stderr is empty
  # TODO(amatej): this is maybe a bug in librepo, we shouln't try to download metadata
  #               from a mirror which fails to serve repomd. Reported as bz1966482
  #               Expected:
  # And HTTP log is
  #    """
  #    GET simple-base /metalink.xml
  #    GET simple-base /repodata/repomd.xml
  #    GET mirror /repodata/repomd.xml
  #    GET mirror /repodata/primary.xml.gz
  #    GET mirror /repodata/filelists.xml.gz
  #    """
  # Instead we get:
  And HTTP log is
      """
      GET simple-base /metalink.xml
      GET simple-base /repodata/repomd.xml
      GET mirror /repodata/repomd.xml
      GET simple-base /repodata/primary.xml.gz
      GET simple-base /repodata/filelists.xml.gz
      GET mirror /repodata/primary.xml.gz
      GET mirror /repodata/filelists.xml.gz
      """


@bz1966482
Scenario: when the first mirror from mirrorlist isn't available we try the next one
Given I copy repository "simple-base" for modification
  And I copy directory "/{context.dnf.repos[simple-base].path}" to "/mirror"
  And I start http server "mirror" at "{context.dnf.installroot}/mirror"
  And I use repository "simple-base" as http
  And I create and substitute file "/mirrorlist" with
      """
      http://localhost:{context.dnf.ports[simple-base]}
      http://localhost:{context.dnf.ports[mirror]}
      """
  And I configure repository "simple-base" with
      | key        | value                                |
      | mirrorlist | {context.dnf.installroot}/mirrorlist |
  And I delete directory "/{context.dnf.repos[simple-base].path}/repodata"
  And I start capturing outbound HTTP requests
 When I execute dnf with args "makecache --refresh"
 Then the exit code is 0
  And stderr is empty
  # TODO(amatej): this is maybe a bug in librepo, we shouln't try to download metadata
  #               from a mirror which fails to serve repomd. Reported as bz1966482
  And HTTP log is
      """
      GET simple-base /repodata/repomd.xml
      GET mirror /repodata/repomd.xml
      GET simple-base /repodata/primary.xml.gz
      GET simple-base /repodata/filelists.xml.gz
      GET mirror /repodata/primary.xml.gz
      GET mirror /repodata/filelists.xml.gz
      """


@bz1966482
Scenario: when the first repomd checksum from metalink doesn't match we should try the next mirror
Given I copy repository "simple-base" for modification
  And I copy directory "/{context.dnf.repos[simple-base].path}" to "/mirror"
  And I start http server "mirror" at "{context.dnf.installroot}/mirror"
  And I use repository "simple-base" as http
  And I set up metalink for repository "simple-base"
  And I add "http://localhost:{context.dnf.ports[mirror]}" mirror to "simple-base" metalink
  # Change repomd.xml from simple-base repo so that it doesn't match with metalink checksum
  Given I generate repodata for repository "simple-base" with extra arguments "--checksum sha512"
  And I start capturing outbound HTTP requests
 When I execute dnf with args "makecache --refresh"
 Then the exit code is 0
  And stderr is empty
  # TODO(amatej): this is maybe a bug in librepo, we shouln't try to download metadata
  #               from a mirror which has different repomd than expected. Reported as bz1966482
  And HTTP log is
      """
      GET simple-base /metalink.xml
      GET simple-base /repodata/repomd.xml
      GET mirror /repodata/repomd.xml
      GET simple-base /repodata/primary.xml.gz
      GET simple-base /repodata/filelists.xml.gz
      GET mirror /repodata/primary.xml.gz
      GET mirror /repodata/filelists.xml.gz
      """


@wip
Scenario: fastestmirror checking is parallel
Given I copy repository "simple-base" for modification
  And I copy directory "/{context.dnf.repos[simple-base].path}" to "/mirror"
  And I start http server "mirror" at "{context.dnf.installroot}/mirror"
  And I use repository "simple-base" as http
  And I create and substitute file "/mirrorlist" with
  """
  http://localhost:{context.dnf.ports[simple-base]}
  http://localhost:{context.dnf.ports[mirror]}
  """
  And I configure repository "simple-base" with
	  | key        | value                                |
	  | mirrorlist | {context.dnf.installroot}/mirrorlist |
  And I start capturing outbound HTTP requests
  # Since we are logging all `handle()` calls for this test clean up the log first because
  # each server has one empty request by default (not from dnf) which would confuse the output
  And I forget any HTTP requests captured so far
  When I execute dnf with args "makecache --refresh --setopt=fastestmirror=1"
  Then HTTP log is
  """
  We can see in the "found" section of the diff that
  the first empty requests (those are from fastests mirror)
  arrive at the same time, the response from both takes 5s
  then we pick the fastest and download from it.
  So fastests mirror is run in parallel because otherwise 
  the first request for data would be delayed by 10s (5+5)
  but it is in fact delayed only by 5s.
  """

  # When run the diff looks like this:
  #    Captured stdout:
  #    expected                                                   |  found
  #    We can see in the "found" section of the diff that         |  22/Nov/2021 08:22:20 ('127.0.0.1', 44949)b''
  #    the first empty requests (those are from fastests mirror)  |  22/Nov/2021 08:22:20 ('127.0.0.1', 36121)b''
  #    arrive at the same time, the response from both takes 5s   |  22/Nov/2021 08:22:25 ('127.0.0.1', 36121)b'GET /repodata/repomd.xml HTTP/1.1\r\nHost: localhost:36121\r\nUser-Agent: libdnf (Fedora 34; container; Linux.x86_64)\r\nAccept: */*\r\nCache-Control: no-cache\r\nPragma: no-cache'
  #    then we pick the fastest and download from it.             |  22/Nov/2021 08:22:30 ('127.0.0.1', 44949)b'GET /repodata/repomd.xml HTTP/1.1\r\nHost: localhost:44949\r\nUser-Agent: libdnf (Fedora 34; container; Linux.x86_64)\r\nAccept: */*\r\nCache-Control: no-cache\r\nPragma: no-cache'
  #    So fastests mirror is run in parallel because otherwise    |  22/Nov/2021 08:22:36 ('127.0.0.1', 36121)b'GET /repodata/repomd.xml HTTP/1.1\r\nHost: localhost:36121\r\nUser-Agent: libdnf (Fedora 34; container; Linux.x86_64)\r\nAccept: */*\r\nCache-Control: no-cache\r\nPragma: no-cache'
  #    the first request for data would be delayed by 10s (5+5)   |  22/Nov/2021 08:22:41 ('127.0.0.1', 36121)b'GET /repodata/repomd.xml HTTP/1.1\r\nHost: localhost:36121\r\nUser-Agent: libdnf (Fedora 34; container; Linux.x86_64)\r\nAccept: */*\r\nCache-Control: no-cache\r\nPragma: no-cache'
  #    but it is in fact delayed only by 5s.                      |
