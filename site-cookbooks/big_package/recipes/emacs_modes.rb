
%w[
  erlang-mode python-mode ruby-elisp ruby1.8-elisp php-mode org-mode nxml-mode
  mmm-mode css-mode gnuplot-mode html-helper-mode lua-mode
].each do |pkg|
  package pkg do
    action :upgrade
  end
end
