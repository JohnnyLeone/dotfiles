"""Exercise Git aliases against local repositories, without contacting remotes."""
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class GitAliases(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dotfiles-git-')
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        self.env = dict(os.environ, HOME=str(self.work), GIT_CONFIG_NOSYSTEM='1',
                        GIT_CONFIG_GLOBAL=str(ROOT / '.gitconfig'))
        self.origin = self.work / 'origin.git'
        self.seed = self.work / 'seed'
        self.clone = self.work / 'clone'
        self.git(self.work, 'init', '--bare', str(self.origin))
        self.git(self.work, 'init', '-b', 'main', str(self.seed))
        self.commit('first')
        self.git(self.seed, 'remote', 'add', 'origin', str(self.origin))
        self.git(self.seed, 'push', '-u', 'origin', 'main')
        self.git(self.work, 'clone', '-b', 'main', str(self.origin), str(self.clone))

    def git(self, directory, *args):
        return subprocess.check_output(['git', '-C', str(directory), *args],
                                       env=self.env, text=True, stderr=subprocess.PIPE)

    def commit(self, message):
        (self.seed / 'file').write_text(message+'\n')
        self.git(self.seed, 'add', 'file')
        self.git(self.seed, 'commit', '-m', message)

    def test_pull_aliases_follow_main_upstream(self):
        for alias in ('p', 'up'):
            self.commit(alias)
            self.git(self.seed, 'push')
            self.git(self.clone, alias)
            self.assertEqual((self.clone / 'file').read_text(), alias+'\n')

    def test_unreleased_uses_nearest_tag_instead_of_lexical_order(self):
        self.git(self.seed, 'tag', 'v2.0')
        self.commit('released-change')
        self.git(self.seed, 'tag', 'v10.0')
        self.commit('unreleased-change')
        diff = self.git(self.seed, 'unreleased')
        self.assertIn('-released-change', diff)
        self.assertNotIn('-first', diff)
        self.assertIn('+unreleased-change', diff)

    def test_up_initializes_new_submodules(self):
        child = self.work / 'child'
        self.git(self.work, 'init', '-b', 'main', str(child))
        (child / 'nested-file').write_text('nested\n')
        self.git(child, 'add', 'nested-file')
        self.git(child, 'commit', '-m', 'nested')
        self.git(self.seed, '-c', 'protocol.file.allow=always', 'submodule',
                 'add', str(child), 'nested')
        self.git(self.seed, 'commit', '-m', 'add submodule')
        self.git(self.seed, 'push')
        self.git(self.clone, '-c', 'protocol.file.allow=always', 'up')
        self.assertEqual((self.clone / 'nested/nested-file').read_text(), 'nested\n')


if __name__ == '__main__':
    unittest.main()
