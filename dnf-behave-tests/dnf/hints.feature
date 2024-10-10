@dnf5
Feature: hints


Scenario: hints
  Given I use repository "hints"
    And I configure dnf with
        | key  | value |
        | best | False |
    And I execute dnf with args "install kexi"
   When I execute dnf with args "update breeze"
   Then the exit code is 0
   # dnf4 hints for --best --allowerasing
   And stdout is
   """
   Package Arch   Version    Repository      Size
   Skipping packages with conflicts:
    breeze noarch 6.6-1.fc29 hints        0.0   B
   Skipping packages with broken dependencies:
    kexi   x86_64 1.0-1.fc29 hints        0.0   B

   Nothing to do.
   """
   And stderr is
   """
   Updating and loading repositories:
   Repositories loaded.
   Problem: problem with installed package
     - installed package kexi-1.0-1.fc29.x86_64 requires breeze = 6.3, but none of the providers can be installed
     - package kexi-1.0-1.fc29.x86_64 from hints requires breeze = 6.3, but none of the providers can be installed
     - cannot install both breeze-6.6-1.fc29.noarch from hints and breeze-6.3-1.fc29.x86_64 from @System
     - cannot install both breeze-6.6-1.fc29.noarch from hints and breeze-6.3-1.fc29.x86_64 from hints
     - cannot install the best update candidate for package breeze-6.3-1.fc29.x86_64
   """
   When I execute dnf with args "update breeze --best --allowerasing"
   Then DNF Transaction is following
        | Action       | Package                    |
        | install-dep  | kf6-0:1.0-1.fc29.x86_64    |
        | upgrade      | breeze-0:6.6-1.fc29.noarch |
        | remove-dep   | kexi-0:1.0-1.fc29.x86_64   |

   Then the exit code is 0
