#
# vim with python3 needed for for YouCompleteMe
#
self: super: {
  vim_configurable = super.vim_configurable.override {
    python3 = self.python3Full;
  };
}
