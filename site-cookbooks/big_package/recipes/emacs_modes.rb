package "emacs23-nox" do
  action :upgrade
end
%w[
  erlang-mode python-mode ruby-elisp ruby1.8-elisp php-mode org-mode
  mmm-mode css-mode html-helper-mode lua-mode
].each do |pkg|
  package pkg do
    action :upgrade
  end

  # SOMETHING LIKE THIS
#   directory "/usr/local/share/emacs/site-lisp" do
#     action :create
#     owner 'group'
#     mode 0775
#     recursive true
#   end

#   cookbook_file "/usr/local/share/emacs/site-lisp/pig-mode.el" do
#     source "pig-mode.el"
#     owner 'group'
#     mode 0664
#     action :create
#   end
  
end
