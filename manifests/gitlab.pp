# == Class: gerrit::gitlab
#
class gerrit::gitlab (
  $gitlab_address,
  $gitlab_protocol = 'http',
  $root_username = 'root',
  $root_passwd,
  $gerrit_name,
  $gerrit_username = 'gerrit',
  $gerrit_email,
  $gerrit_passwd,
  $gerrit_pub_key_title,
  $gerrit_pub_key = '/home/gerrit2/.ssh/id_rsa.pub',
  $gerrit_priv_key = '/home/gerrit2/.ssh/id_rsa',
){
    include ::pip

    package { 'pyapi-gitlab':
      ensure   => latest,  # okay to use latest for pip
      provider => pip,
      require  => Class['pip'],
    }

    file { '/home/gerrit2/.ssh/config':
      ensure  => present,
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0644',
      content => template('gerrit/ssh_config.erb'),
    }

    file { '/home/gerrit2/review_site/bin/update-gitlab.py':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => 'puppet:///modules/gerrit/update-gitlab.py',
    }

    file { '/etc/gitlab':
      ensure => directory,
      group  => 'root',
      mode   => '0755',
      owner  => 'root',
    }

    file { '/etc/gitlab/gitlab-projects.secure.config':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('gerrit/gitlab.conf.erb'),
      replace => true,
      require => File['/etc/gitlab'],
    }

    exec { 'update_gitlab':
        command     => '/home/gerrit2/review_site/bin/update-gitlab.py',
        timeout     => 30, # 30 seconds
        subscribe   => [
            File['/etc/gitlab/gitlab-projects.secure.config'],
            File['/home/gerrit2/review_site/bin/update-gitlab.py'],
            File['/home/gerrit2/.ssh/id_rsa'],
            File['/home/gerrit2/.ssh/id_rsa.pub'],
          ],
#        refreshonly => true,
        require     => [
            File['/etc/gitlab/gitlab-projects.secure.config'],
            File['/home/gerrit2/review_site/bin/update-gitlab.py'],
            File['/home/gerrit2/.ssh/id_rsa'],
            File['/home/gerrit2/.ssh/id_rsa.pub'],
            File['/home/gerrit2/.ssh/config'],
        ],
      }

}
