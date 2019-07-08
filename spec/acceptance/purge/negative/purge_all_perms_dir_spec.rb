require 'spec_helper_acceptance'

describe 'Purge' do
  def acl_manifest(target)
    <<-MANIFEST
      file { "#{target_parent}":
        ensure => directory
      }

      file { "#{target}":
        ensure  => directory,
        require => File['#{target_parent}']
      }

      user { "#{user_id}":
        ensure     => present,
        groups     => 'Users',
        managehome => true,
        password   => "L0v3Pupp3t!"
      }

      acl { "#{target}":
        permissions  => [
          { identity => '#{user_id}', rights => ['full'] },
        ],
      }
    MANIFEST
  end

  def purge_acl_manifest(target)
    <<-MANIFEST
      acl { "#{target}":
        purge        => 'true',
        permissions  => [],
        inherit_parent_permissions => 'false'
      }
    MANIFEST
  end

  context 'Negative - Purge Absolutely All Permissions from Directory without Inheritance' do
    target = "#{target_parent}/purge_all_no_inherit"

    verify_acl_command = "icacls #{target}"
    acl_regex_user_id = %r{.*\\bob:\(OI\)\(CI\)\(F\)}

    verify_purge_error = %r{Error:.*Value for permissions should be an array with at least one element specified}

    windows_agents.each do |agent|
      context "on #{agent}" do
        it 'Execute Apply Manifest' do
          execute_manifest_on(agent, acl_manifest(target), debug: true) do |result|
            expect(result.stderr).not_to match(%r{Error:})
          end
        end

        it 'Verify that ACL Rights are Correct' do
          on(agent, verify_acl_command) do |result|
            expect(result.stdout).to match(%r{#{acl_regex_user_id}})
          end
        end

        it 'Attempt to Execute Purge Manifest' do
          execute_manifest_on(agent, purge_acl_manifest(target), debug: true, exepect_failures: true) do |result|
            expect(result.stderr).to match(%r{#{verify_purge_error}})
          end
        end
      end
    end
  end
end
