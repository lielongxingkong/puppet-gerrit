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

    file { '/home/gerrit2/review_site/etc/gitlab.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('gerrit/gitlab.conf.erb'),
      replace => true,
      require => File['/home/gerrit2/review_site/etc'],
    }

    exec { 'update_gitlab':
        command     => '/home/gerrit2/review_site/bin/update-gitlab.py',
        timeout     => 30, # 30 seconds
        subscribe   => [
            File['/home/gerrit2/review_site/etc/gitlab.conf'],
            File['/home/gerrit2/review_site/bin/update-gitlab.py'],
            File['/home/gerrit2/.ssh/id_rsa'],
            File['/home/gerrit2/.ssh/id_rsa.pub'],
          ],
#        refreshonly => true,
        require     => [
            File['/home/gerrit2/review_site/etc/gitlab.conf'],
            File['/home/gerrit2/review_site/bin/update-gitlab.py'],
            File['/home/gerrit2/.ssh/id_rsa'],
            File['/home/gerrit2/.ssh/id_rsa.pub'],
            File['/home/gerrit2/.ssh/config'],
        ],
      }

}
