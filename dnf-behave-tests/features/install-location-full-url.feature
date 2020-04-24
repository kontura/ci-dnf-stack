Feature: Install packages with full url location


Scenario: Install from local repodata with locations pointing to remote packages
Given I make packages from repository "dnf-ci-fedora" accessible via http
  And I copy repository "dnf-ci-fedora" for modification
  And I execute "createrepo_c --location-prefix http://localhost:{context.dnf.ports[dnf-ci-fedora]} /{context.dnf.repos[dnf-ci-fedora].path}"
  And I use repository "dnf-ci-fedora"
  # delete packages from copied repo for modification so they cannot be accidentaly used
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
  And I execute "createrepo_c --location-prefix http://localhost:{context.dnf.ports[dnf-ci-fedora]} /{context.dnf.repos[dnf-ci-fedora].path}"
  And I use repository "dnf-ci-fedora" as http
  # delete packages from copied repo for modification so they cannot be accidentaly used
  And I delete directory "/{context.dnf.repos[dnf-ci-fedora].path}/noarch"
 When I execute dnf with args "install setup"
 Then the exit code is 0
  And stderr is empty
  And Transaction is following
      | Action        | Package                                  |
      | install       | setup-0:2.12.1-1.fc29.noarch             |
