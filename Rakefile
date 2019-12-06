#!/usr/bin/env ruby
# encoding: binary
#

PROJET = "seqata"

# Retourne le répertoire contenant ce Rakefile (quelque soit l'endroit où l'on est)
# e.g.  /Users/diam/live/public_html/uma/pub/work/sf/mpro_proj/Rakefile
def appdir
  return "#{File.dirname(__FILE__)}"
end

task :default => [:help]


desc "Fournit une aide minimaliste de ce Rakefile"
task :help do
  puts ""
  puts "Rakefile spécifique au projet \"#{PROJET}\""
  puts ""
  puts "Quelques options utiles de rake "
  puts ""
  puts "   rake -T  : liste des taches documentées par desc "
  puts "   rake -P  : liste des dépendances"
  puts "   rake -D  : Describe"
  puts ""
end

desc "Nettoyage du projet (_tmp)"
desc "DANGER : supprime toutes les **solutions** générées (. et _tmp)"
task :rmsol do |t|
  dirs=[".", "_tmp"]
  for dir in dirs
    sh "rm -f #{dir}/alp_*.ampl-*.sol  #{dir}/alp_p*=*.sol"
  end
end
desc "DANGER : supprime **tous les fichiers** du sous-répertoire générées _tmp/"
task :dc do |t|
  dir="_tmp"
  sh "rm -f #{dir}/*"
end


desc "Crée une archive datée (xxx-gitarc.txz) avec git " +
      'eg : rake gitarc suf=""'
task :gitarc do
  suf = ENV["suf"] || ""
  do_gitarc pwd, suf
end

# Crée une archive "-gitarc.txz" datée du répertoire dir à coté de dir
# dir: répertoire de l'archive à créer
# suf: suffixe à ajouter dans le nom de l'archive datée (apres la date
#      et avant le suffixe réel
#
# Vide le répertoire
#
# Voir de mon script shell ~/local/bin/z (pour modèle) :
#
#   bdir=$(basename $(pwd))
#   new_bdir=$bdir-`dateString`
#   git archive --prefix "${new_bdir}-gitarc/" ${what} \
#       | xz -c  > ../${new_bdir}-gitarc.txz
#
def do_gitarc(dir, suf="")

  # Paramètre spécifique à git
  what = "HEAD:"

  # On s'assure que si le suffixe existe, il commence par "-"
  suf = "-"+suf unless suf.start_with?("-")

  # On se positionne à la racine du projet (même si pas nécessaire avec git)
  dir_ori = pwd
  cd appdir

  bname = File.basename(dir)
  date = Time.now.strftime("%Y%m%d_%Hh%M")
  datename = "#{bname}-#{date}-gitarc"

  cmd  = ""
  cmd += " git archive --prefix \"#{datename}/\"  #{what}"
  cmd += " | xz -c  > \"../#{datename}#{suf}.txz\" "

  # puts "POUR INFO : cmd=#{cmd}"
  sh cmd
  # puts "=> fait: #{cmd}"

  cd dir_ori
end


#
# Quelques cibles standards (compression...)
#

desc "Crée une archive datée (xxx.txz) dans le répertoire parent"
task :txz do
  do_txz pwd
end
desc "Crée une archive datée (xxx-stamp.txz) dans le répertoire parent"
task :txzstamp do
  do_txz pwd, "-stamp"
end
desc "Crée une archive datée (xxx.tbz) dans le répertoire parent"
task :tbz do
  do_tbz pwd
end
desc "Crée une archive datée (xxx-stamp.tbz) dans le répertoire parent"
task :tbzstamp do
  do_tbz pwd, "-stamp"
end
desc "Crée une archive datée (xxx.zip) dans le répertoire parent"
task :zip do
  do_zip pwd
end
desc "Crée une archive datée (xxx-stamp.zip) dans le répertoire parent"
task :zipstamp do
  do_zip pwd, "-stamp"
end

# Crée un archive "txz" datée du répertoire dir à coté de dir
# dir: répertoire de l'archive à créer
# suf: sufixe à ajouter dans le nom de l'archive datée (apràs la date
#      et avant le suffixe réel
def do_txz(dir, suf="")
  dir_ori = pwd
  dir_parent = File.dirname(dir)
  bname = File.basename(dir)
  date = Time.now.strftime("%Y%m%d_%Hh%M")
  ## datename = "#{bname}—#{date}" ##!!!  BUG du "-" !!!
  datename = "#{bname}-#{date}"

  cmd = "cd #{dir_parent}"
  cmd += " && cp -Rp '#{bname}' '#{datename}' "
  cmd += " && tar cf - #{datename}"
  cmd += " | xz > '#{datename}#{suf}.txz' &&  rm -R '#{datename}'"
  cmd += " && cd #{dir_ori}"

  # puts "POUR INFO : cmd=#{cmd}"
  sh cmd
  # puts "=> fait: #{cmd}"
end

# Crée un archive "tbz" datée du répertoire dir à coté de dir
# dir: répertoire de l'archive à créer
# suf: sufixe à ajouter dans le nom de l'archive datée (apràs la date
#      et avant le suffixe réel
def do_tbz(dir, suf="")
  dir_ori = pwd
  dir_parent = File.dirname(dir)
  bname = File.basename(dir)
  date = Time.now.strftime("%Y%m%d_%Hh%M")
  ## datename = "#{bname}—#{date}" ##!!!  BUG du "-" !!!
  datename = "#{bname}-#{date}"

  cmd = "cd #{dir_parent}"
  cmd += " && cp -Rp '#{bname}' '#{datename}' "
  cmd += " && tar cf - #{datename}"
  cmd += " | bzip2 > '#{datename}#{suf}.tbz' &&  rm -R '#{datename}'"
  cmd += " && cd #{dir_ori}"

  # puts "POUR INFO : cmd=#{cmd}"
  sh cmd
  # puts "=> fait: #{cmd}"
end
# Crée un archive "zip" datée du répertoire dir à coté de dir
# dir: répertoire de l'archive à créer
# suf: sufixe à ajouter dans le nom de l'archive datée (apràs la date
#      et avant le suffixe réel
def do_zip(dir, suf="")
  dir_ori = pwd
  dir_parent = File.dirname(dir)
  bname = File.basename(dir)
  date = Time.now.strftime("%Y%m%d_%Hh%M")
  ## datename = "#{bname}—#{date}" ##!!!  BUG du "-" !!!
  datename = "#{bname}-#{date}"

  cmd = "cd #{dir_parent}"
  cmd += " && cp -Rp '#{bname}' '#{datename}' "
  cmd += " && zip -r -y -o -q -9 '#{datename}#{suf}.zip'  '#{datename}'"
  cmd += " && rm -R '#{datename}'"
  cmd += " && cd #{dir_ori}"

  # puts "POUR INFO : cmd=#{cmd}"
  sh cmd
  # puts "=> fait: #{cmd}"
end

