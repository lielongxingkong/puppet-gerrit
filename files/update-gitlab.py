import os
import gitlab
import ConfigParser 

CONFIG = '/root/gitlab.conf'
#CONFIG = '/etc/gitlab.conf'

cf = ConfigParser.ConfigParser() 
cf.read(CONFIG)
GITLAB_ADDRESS = cf.get('gitlab', 'gitlab_address', 'gitlab.incloud-ci.com')
GITLAB_PROTOCOL = cf.get('gitlab', 'gitlab_protocol', 'http')
GITLAB_URL = '%s://%s' % (GITLAB_PROTOCOL, GITLAB_ADDRESS)
ROOT_USERNAME = cf.get('gitlab', 'root_username','root')
ROOT_PASSWD = cf.get('gitlab', 'root_passwd')
GERRIT_NAME = cf.get('gitlab', 'gerrit_name', 'InCloud-CI Gerrit')
GERRIT_USERNAME = cf.get('gitlab', 'gerrit_username', 'gerrit')
GERRIT_EMAIL = cf.get('gitlab', 'gerrit_email', 'gerrit@incloud-ci.com')
GERRIT_PASSWD = cf.get('gitlab', 'gerrit_passwd')
GERRIT_SSH_KEY_TITLE = cf.get('gitlab', 'gerrit_ssh_key_title', 'review.incloud-ci.com')
GERRIT_SSH_KEY = open(cf.get('gitlab', 'gerrit_ssh_key', '/home/gerrit2/.ssh/id_rsa.pub')).readline().strip()

class GerritGitlab:
    def __init__(self):
        self.git = self.connect()
        self.make_gerrit_user()
        self.git = self.reconnect()
        self.make_gerrit_key()

    def connect(self):
        git = gitlab.Gitlab(GITLAB_URL)
        git.login(ROOT_USERNAME, ROOT_PASSWD)
        return git

    def _find_user(self, username):
        for u in self.git.getusers():
            if username == u['username']:
                return u

    def make_gerrit_user(self):
        gerrit_user = self._find_user(GERRIT_USERNAME)
        if not gerrit_user:
            self.git.createuser(GERRIT_NAME, GERRIT_USERNAME, GERRIT_PASSWD, GERRIT_EMAIL, confirm = False)
            gerrit_user = self._find_user(GERRIT_USERNAME)
        self.gerrit_user = gerrit_user
        assert self.gerrit_user

    def reconnect(self):
        git2 = gitlab.Gitlab(GITLAB_URL)
        git2.login(GERRIT_USERNAME, GERRIT_PASSWD)
        return git2

    def make_gerrit_key(self):
        gerrit_key = self._find_key(GERRIT_SSH_KEY)
        if not gerrit_key:
            self.git.addsshkey(GERRIT_SSH_KEY_TITLE, GERRIT_SSH_KEY)
            gerrit_key = self._find_key(GERRIT_SSH_KEY)
        self.gerrit_key = gerrit_key
        assert self.gerrit_key

    def _find_key(self, key):
        for k in self.git.getsshkeys():
            if unicode(key) == k['key']:
                return k

    def test(self):
        os.system('ssh -T -oStrictHostKeyChecking=no git@%s' % GITLAB_ADDRESS)
        

if __name__ == "__main__":
    gg = GerritGitlab()
    gg.test()
