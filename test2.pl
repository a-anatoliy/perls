#!/usr/bin/perl
use strict; use warnings;
use Data::Dumper;

unless (@ARGV) { print "\n The name of new project wasn't given.\n"; exit; }

use constant {
	DEF_CONFIG  => 'base.conf',
	# TEMPLATE 	=> 'v_host.tmpl',
	TEMPLATE 	=> 'new_Vhost.tmpl',
	# APACHE_PATH => '/etc/apache2/sites-available/',
	APACHE_PATH => '/etc/apache2/conf-available/',
	#APACHE_PATH => '/home/webmaster/sites-available/',
};

my $config = {
	'HOME' => '/home/webmaster/sites',
	'PROJECT_POSTMASTER' => 'a3three@gmail.com',
	# 'directories' => [qw(www cgi-bin data edit logs data/templates data/sess i init libs)],
	'directories' => [qw(img data vendor js css fonts data/sess)],
	'index' => 'index.php',
	# 'hosts' => 'hosts_copy.txt',
	# 'apache_bin' => '/etc/init.d/apache2',
	'hosts' => '/etc/hosts',
	'apache_bin' => 'apache2',
};

$config->{'NAME_OF_PROJECT'} = shift @ARGV;
$config->{'WORK_DIR'} = qq!$config->{'HOME'}/$config->{'NAME_OF_PROJECT'}!;
$config->{'createdTimeStr'} = scalar(localtime);

if (-d $config->{'WORK_DIR'}) {
	print "\n The project already exists: $config->{'WORK_DIR'}\n";
	exit; 
	# &runCMD('','rm','-rf',$config->{'WORK_DIR'});
	# &runCMD('','rm',qq~${\APACHE_PATH}$config->{'NAME_OF_PROJECT'}.conf~) if -e qq~${\APACHE_PATH}$config->{'NAME_OF_PROJECT'}.conf~;
	# print "\n\terased...\n";
}

&main();
exit;


sub main {
# `sudo usermod -a -G webmaster www-data`;
# &runCMD('Add group www-data to current user … ','usermod', '-a', '-G', 'webmaster', 'www-data');
exit unless &runCMD(" Creating project working directory: $config->{'WORK_DIR'}",'mkdir','-p',$config->{'WORK_DIR'});
&createDirTree($config->{'directories'});
&createVHconfig();
&runCMD("Set permission to: $config->{'WORK_DIR'}",'chmod','-R',777,$config->{'WORK_DIR'});
# &addToHosts();
# a2dissite;

###  &runCMD('Enabling new VH. ','a2ensite',qq~$config->{'NAME_OF_PROJECT'}.conf~);
###  &runCMD('Reload Apache … ','service',$config->{'apache_bin'},'reload');
&createDefIndex();
print '-- FAIL!' unless &checkVHavailability();
my $r = &runCMD("Final Work Directory Listing '$config->{WORK_DIR}': \n",'ls','-laF',$config->{'WORK_DIR'});

return 1;
}

sub createDefIndex {
	print "\n".'Create default index file';
	my $dirsString = join('<br>', @{$config->{directories}});
	open(HTML,'>>',qq~$config->{'WORK_DIR'}/$config->{index}~)|| die "\nCan't open index file: $!";
	print HTML qq~
	<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
	<title> $config->{'NAME_OF_PROJECT'} </title></head><body><hr><table>
	<tr><td align="right">PROJECT:     </td><td>$config->{NAME_OF_PROJECT}</td></tr>
	<tr><td align="right">CREATED:     </td><td>$config->{createdTimeStr}</td></tr>
	<tr><td align="right">WORK DIR:    </td><td>$config->{WORK_DIR}</td></tr>
	<tr><td align="right">DIRECTORIES: </td><td>$dirsString</td></tr></table><hr></BODY></html>
	~; close(HTML);
	print ' -- DONE!';
return 1;
}

sub checkVHavailability {
return 
	&runCMD('Get the index page from new VH ','wget','-q','--spider',qq~http://localhost/$config->{'NAME_OF_PROJECT'}/~)
	? 1 : 0;
}

sub createDirTree {
	my $dir = shift;
	my $mess = ' Creating';
	if (ref $dir eq 'ARRAY') {
		$mess .= ' directories … ['.scalar (@{$dir}).']';
		print "\n".$mess;
		for (@{$dir}) {
			exit unless &runCMD(qq~\tCreating: $config->{'WORK_DIR'}/$_~,'mkdir','-p',qq~$config->{'WORK_DIR'}/$_~);
		}
	}
return scalar (@{$dir});
}

sub createVHconfig {
	my $templatePath = ${\TEMPLATE};
	my $v_host_conf = qq~${\APACHE_PATH}$config->{'NAME_OF_PROJECT'}.conf~;
	print "\n".'Creating config of VH: '.$v_host_conf;

	open(TMPL, $templatePath)      || die "\nCan't open $templatePath: $!";
		open(VHC,">",$v_host_conf) || die "\nCan't open $v_host_conf: $! $@";
		while (defined (my $line = <TMPL>)) {
			$line =~ s/%NAME_OF_PROJECT%/$config->{'NAME_OF_PROJECT'}/g;
			$line =~ s#%PROJECT_POSTMASTER%#$config->{'PROJECT_POSTMASTER'}#g;
			$line =~ s#%WORK_DIR%#$config->{'WORK_DIR'}#g;
			print VHC $line;
		}
	close(TMPL); close(VHC);
	print ' -- DONE!';
}

sub runCMD {
my $mess = shift;
print "\n".$mess if $mess;
system(@_) == 0 || return undef;
print ' -- DONE!';
return 1;
}

sub addToHosts {
	print "\n"."Adding new host: $config->{'NAME_OF_PROJECT'} to hosts file: $config->{'WORK_DIR'}";
	open(H,">>",$config->{'hosts'}) || die "Can't open $config->{'hosts'}: $!";
	print H qq~\n127.0.0.1\t$config->{'NAME_OF_PROJECT'}~;
	close(H);
	print ' -- DONE!';
}


__END__
=comment
###############################################################################
GRANT ALL PRIVILEGES ON $NAME_OF_PROJECT.* TO ${NAME_OF_PROJECT}_user@localhost IDENTIFIED by '$DB_PASS'  WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO webmaster@"%" IDENTIFIED BY 'm7996910' WITH GRANT OPTION;
#создаем папки проекта
sudo mkdir /home/www/$NAME_OF_PROJECT
sudo mkdir /home/www/$NAME_OF_PROJECT/public/
sudo mkdir /home/www/$NAME_OF_PROJECT/cgi-bin/
sudo mkdir /home/www/$NAME_OF_PROJECT/logs/

#указываем владельца и права на папку "public"
sudo chown -R www-data:www-data /home/www/$NAME_OF_PROJECT/
sudo chmod -R 755 /home/www/$NAME_OF_PROJECT/
sudo chown -R www-data:www-data /home/www/$NAME_OF_PROJECT/public/
sudo chmod -R 755 /home/www/$NAME_OF_PROJECT/public/

# Создаем страничку в public для того чтобы сайт хоть что-то отражал
touch /home/www/$NAME_OF_PROJECT/public/index.html
echo "Поздравляем Ваш сайт работает $NAME_OF_PROJECT" >> /home/www/$NAME_OF_PROJECT/public/index.html
sudo chown -R www-data:www-data /home/www/$NAME_OF_PROJECT/public/index.html
###############################################################################
1) В консольке добавить www-data в группу домашнего пользователя
sudo usermod -a -G webmaster www-data
, проверим наличие пользователя
groups www-data
###############################################################################

Создаете пользователя, например user1, и включаете его в группу www-data.
В /home/user1 создаете каталог /home/user1/www. Ну а дальше создаете виртуальный хост с путями /home/user1/www.


/etc/apache2/sites-available/default добавить директиву:

NameVirtualHost 192.168.0.1
Там необходимо указать IP адрес либо DNS имя компютера на котором размещён вебсервер, можно указать localhost или 127.0.0.1

Затем, учитывая организацию конфигов apache2 в Debian, необходимо создать файл виртуального хоста в директории: /etc/apache2/sites-available/
например ваш сайт называется supebreys.ru, значит логичнее создать чтото вроде /etc/apache2/sites-available/supebreys_ru.conf. В любом случае это название должно 
вам говорить для чего этот файл и будет лучше если вы будете придерживаться какого то одного правила создания таких файлов. Затем в этот файл добавляем такой текст:

<VirtualHost *:80>
        DocumentRoot "/home/httpd/breys.ru/www"
        ServerName    breys.xxx 
        <Directory />
                allow from all
                Options +Indexes
       </Directory>
        ScriptAlias /cgi-bin/ "/home/httpd/breys.ru/cgi-bin/"
        CustomLog  /home/httpd/breys.ru/access.log common
        ErrorLog /home/httpd/breys.ru/error.log
</VirtualHost>
 
Здесь мы создали виртуальный хост которых будет обрабатывать запросы на 80 порту с любого доступного адреса
Также тут указана корневая директория сайта, директория с cgi скриптами и пути к файлам журналов работы вебсервера
Для корневой директори указаны дополнительные(необязательные) опции: разрешение доступа с любого адреса и включение модуля обработки индексного файла, 
в принципе эти опции не обязательны и нужны только если прихоится переопределять глобальные политики доступа и загрузки модулей вебсервером

После создания этого файла веб сервер ещё не видит его. Если внимательно посмотреть на файлы в директориях /etc/apache2/sites-enabled/ и 
/etc/apache2/sites-available/ то должно стать ясно, то что в директории /etc/apache2/sites-available лежат файлы описывающие виртуальные хосты, а в 
папке/etc/apache2/sites-enabled/ лежат симлинки на файлы в sites-available.  Исходя из названий становится ясно, что:
sites-available - все доступные виртуальных хосты
sites-enabled - включаемые вебсервером
то есть, чтобы добавить виртульный хост в apache2, необходимо либо создать файл нового виртуального хоста в sites-available либо дописать(не желательно)
его в уже имеющийся там файл, а чтобы включить виртуальный хост, необходимо чтобы директории sites-enabled была ссылка на файл описывающий виртуальных хост

Это сделанно для того, чтобы разделить виртуальные домены на уровне хостинга. Например, хостер чтобы временно удалить какой то домен удаляет ссылку из папки 
sites-enabled и перезапускает вебсервер и так же быстро включает домен снова, без правки единого конфига, как это было реализованно ранее.

Итак, включаем наш, только что созданный, новых виртуальный хост:

ln -s /etc/apache2/sites-available/breys_ru.conf /etc/apache2/sites-enabled/breys_ru.conf
Этой командой мы создаём симлинк(символическую ссылку на один файл в другой директории) на рабочий файл виртуального хоста, который будет обработан при 
следующем перезапуске вебсервера

Возможно вам потребуется расширить поведение вашего виртуального хоста - может потребоваться чтобы он был доступен по нескольким адреса

Например, у меня имеются зеркала моих сайтов и я работаю с ними дома используя имена сайтов + моя домашняя зона .xxx, тоесть для сайта breys.ru у меня есть домашнее 
зеркало breys.xxx, но вполне вероятна ситуация когда нужно показать зеракло ещё кому то, тогда я могу использовать DNS зону зарегистрированную за мной на 
DYNDNS.COM, тоесть это зеркало имеет дополнительный адрес в виде:breys.ffsdmad.homelinux.org, ещё более частая ситуация когда нужно иметь имя www.breys.ru и 
соответственноwww.breys.ffsdmad.homelinux.org
Чтобы включить этого необходимо в файл виртального хоста, внутри инструкций .. добавить список необходимых алиасов:

<VirtualHost *:80>
 ....другие инструкции
  ServerName breys.xxx
  ....
  ServerAlias www.breys.xxx
  ServerAlias breys.ffsdmad.homelinux.org
  ServerAlias www.breys.ffsdmad.homelinux.org
  ....
</VirtualHost>
Вполне возможно придётся заниматься отладкой модуля mod_rewrite, для этого необходимо в файл виртуального хоста добавить строки:

<VirtualHost *:80>
 ....другие инструкции
 RewriteLog /home/httpd/breys.ru/rewrite.log
 RewriteLogLevel 9 
</VirtualHost>
Начните с небольшого примера и постепенно расширяйте возможности своего виртуального хостинга различными возможностями вебсервера apache2 (а их у него предостаточно) 
и постепенно вы поймёте насколько проста и логична такая структура в условиях такого сложного сервиса как вебхостинг

Также следует заметить, что если вы поставили на локальную машину сервер apache2 и виртуальные хосты прописаны в /etc/hosts (соответствия имени ip адресу), 
то начинаются тормоза при обращении к вебсерверу. Дело в том, что браузер сначала пытается распознать ip адрсе у dns сервера, который у вас прописан в 
/etc/resov.conf, а не проверять файл /etc/hosts. Это можно исправить заменив в файле /etc/host.conf последовательность перебора сервисов разрешения имён, 
но лучше всего настроить bind и забыть про тормоза и проблемы с обратным разрешением имени по IP
=cut

=comment
LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
Строка начинается с LogFormat и сообщает Apache, что вы определили тип файла лога, в данном случае - комбинированный. 
Сейчас давайте взглянем на символы, которые составляют определение формата сообщения.
%h	IP адрес клиента (удаленного хоста).
%l	Имя пользователя (от identd).
%u	userid удаленного пользователя (полезно при HTTP авторизации).
%t	Дата и время запроса.
%r	Строка запроса.
%s	Код статуса, отсылаемый сервером клиенту (201, 301, 404, 500, и т.д.). Символ > перед s показывает, что в лог записывается только последний статус.
%b	Количество отправленных байтов клиенту (HTTP заголовки не учитываются).
%i	Элементы, передаваемые в HTTP заголовках. Таким образом, добавляя Referer и User-Agent можно отслеживать ссылающиеся URL и типы браузеров.


ErrorLog logs/error_log
LogLevel warn
LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%h %l %u %t \"%r\" %>s %b" common
LogFormat "%{Referer}i -> %U" referer
LogFormat "%{User-agent}i" agent
CustomLog logs/access_log combine
=cut




