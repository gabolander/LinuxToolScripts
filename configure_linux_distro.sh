#!/bin/bash
LANG="it_IT.UTF-8"
export LANG

PRG=`basename $0`
PRGBASE=`basename $0 .sh`
PRGDIR=`dirname $0`
VERSION="1.01.2"
WRITTEN_STARTED="25-03-2012"
LAST_UPD="10-07-2017"

COL_YELLOW="\033[1;33m";    COLESC_YELLOW=`echo -en "$COL_YELLOW"`
COL_BROWN="\033[0;33m";     COLESC_BROWN=`echo -en  "$COL_BROWN"`
COL_RED="\033[0;31m";       COLESC_RED=`echo -en    "$COL_RED"`
COL_LTRED="\033[1;31m";     COLESC_LTRED=`echo -en  "$COL_LTRED"`
COL_BLUE="\033[0;34m";      COLESC_BLUE=`echo -en   "$COL_BLUE"`
COL_LTBLUE="\033[1;34m";    COLESC_LTBLUE=`echo -en "$COL_LTBLUE"`
COL_GREEN="\033[0;32m";     COLESC_GREEN=`echo -en  "$COL_GREEN"`
COL_LTGREEN="\033[1;32m";   COLESC_LTGREEN=`echo -e "$COL_LTGREEN"`
COL_WHITE="\033[0;37m";     COLESC_WHITE=`echo -en  "$COL_WHITE"`
COL_LTWHITE="\033[1;37m";   COLESC_LTWHITE=`echo -en "$COL_LTWHITE"`
COL_RESET=`tput sgr0`;        COLESC_RESET=`echo -en  "$COL_RESET"`
COL_UL=`tput smul`
COL_BLINK=`tput blink`


ACTDIR=`pwd`
OGGI=`date +%Y%m%d`
OGGI_ITA=`date +%d-%m-%Y`
ORA_ITA=`date +%H:%M:%S`
if [ -z "$HOSTNAME" ]; then
  HOSTNAME=`hostname`
fi
TMPDIR=`mktemp -d /tmp/${PRGBASE}_temp_dir_XXXXX`
TMP1="$TMPDIR/${PRGBASE}-1_temp"
TMP2="$TMPDIR/${PRGBASE}-2_temp"
TMP3="$TMPDIR/${PRGBASE}-2_temp"
TEMPORANEI="$TMPDIR"

## Log
LOGDIR="/var/log"
LOGFILE="${LOGDIR}/${PRGBASE}.log"
LOGFILEXT="${LOGDIR}/${PRGBASE}-ext-${OGGI}.log"


# declare -a sms_errors=('child procs already',"lerrore di stacippa")  #Per ora solo uno
# Recipients="<gabriele.zappi@somedomain.net>,<gabo@mailme.com>"
# declare -a codici_esclusi=("M01234" "M19099")  # array 


### Comandi
TAR=`type -p tar`
GREP=`type -p grep`
CAT=`type -p cat`
SSH=`type -p ssh`
SCP=`type -p scp`
SORT=`type -p sort`
UNIQ=`type -p uniq`
FDUPES=`type -p fdupes`
RSYNC=`type -p rsync`
EXIFTOOL=`type -p exiftool`
DIALOG=`type -p dialog`

######
# Libreria funzioni
if [ -f "$PRGDIR/bash_functions_lib.inc.sh" ]; then
  . "$PRGDIR/bash_functions_lib.inc.sh"
fi

####
#  Funzioni
#
function at_exit()
{
  if [ "$1" -gt 0 -a "$1" -lt 32 ]; then
    echo -n "Bad exit for : "
  else
#     echo "Uscita regolare." # debug
      echo
  fi 
      
  case "$1" in
     1) 
      echo "SIGHUP    /* Hangup (POSIX).  */"
      ;;
     2) echo "SIGINT    /* Interrupt (ANSI).  */"
      ;;
     3) echo "SIGQUIT   /* Quit (POSIX).  */"
      ;;
     9) echo "SIGKILL   /* Kill, unblockable (POSIX).  */"
      ;;
     12) echo "SIGUSR2     /* User-defined signal 2 (POSIX).  */"
      ;;
     13) echo "SIGPIPE     /* Broken pipe (POSIX).  */"
      ;;
     15) echo "SIGTERM     /* Termination (ANSI).  */"
      ;;
  esac

  rm -rf "$TEMPORANEI"
  exit $1
}

sino()
{
  SINO=""
  DEF=""
  TMP=""
  MSG=`echo "$1" | cut -c1`
  if [ "$MSG" = "-" ]; then
    MSG=""
  else
    MSG="$1"
  fi

  if [ -z "$2" ]; then
    TMP="$1"
  else
    TMP="$2"
  fi
  TMP=`echo $TMP | tr [:lower:] [:upper:]`
  DEF=`echo $TMP | cut -c1`
  if [ -n "$MSG" -a -n "$DEF" ]; then
	MSG="$MSG [def=$DEF]"
  fi

  while [ "$SINO" != "Y" -a  "$SINO" != "N" ]; do
    echo -n "$MSG :"
    read SINO
    [ -z "$SINO" ] && SINO=$DEF
    SINO=`echo $SINO | tr [:lower:] [:upper:]`
    if [ "$SINO" != "Y" -a  "$SINO" != "N" ]; then
	echo "Please answer with Y or N."
    fi
  done
}

function trim()
{
    trimmed=$(echo -e "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    echo "$trimmed"
}

function escapedot() 
{ 
	in=$1
	out=$(echo "$in" | sed "s/\./\\\./g")
	echo "$out"
}


proseguo()
{
  RISP=""
  while [ "$RISP" != "Y" ]; do
    echo -ne "\n Continue ('Y' for Yes, CTRL+C to interrupt) : "
    read RISP
#   RISP=`echo $RISP | tr [:lower:] [:upper:]`
  done
}

pinvio()
{
  echo -ne "\n Press [ENTER] to continue. "
  read RISP
  echo " "
}



function agg_ora()
{
  OGGI=`date +%Y%m%d`
  OGGI_ITA=`date +%d-%m-%Y`
  ORA_ITA=`date +%H:%M:%S`
  DATAIERI=`date -d yesterday +%Y%m%d`
}

function help()
{
	ret=0
	if [ -n "$1" ]; then
		echo "$1"
		echo
	fi
	if [ -n "$2" ]; then
		ret=$2
	fi
  cat<<!EOM
 Uso $PRG : 
     $PRG <parametri>
          parametri:
          -h | --help  = This help screen
!EOM
  at_exit $ret
}

function logga()
{
	[ -n "$QUIET" ] || echo "$1"
	echo "$1" >> $LOGFILE
	[ -z "$DEBUG" ] || echo "$1" >> $LOGFILEXT
}


function valuta_parametri() {
#!/bin/sh

# Si raccoglie la stringa generata da getopt.
# STRINGA_ARGOMENTI=`getopt -o aB:c:: -l a-lunga,b-lunga:,c-lunga:: -- "$@"`
STRINGA_ARGOMENTI=`getopt -o hB:Sfy -l help,repo-dir:,repobase-directory:,simulate,fdupes,yes -- "$@"`


# Inizializzazione parametri di default
REPOBASE_DIR=""
SIMULATE=""
USE_FDUPES=""
ANS_YES=""

# Si trasferisce nei parametri $1, $2,...
eval set -- "$STRINGA_ARGOMENTI"

while true ; do
#		echo "Param = $1" # debug
    case "$1" in
#        -a|--a-lunga)
#            echo "Opzione a" # debug
#            shift
#            ;;
	-h|--help)
			shift
			help
			;;
	-f|--fdupes)
			shift
			USE_FDUPES="yes"
			;;
	-y|--yes)
			shift
			ANS_YES="yes"
			;;
        -B|--repo-dir*|--repobase-dir*)
            # echo "Opzione b, argomento «$2»" # debug
						[ -z "$2" ] && at_exit 99
						REPOBASE_DIR="$2"
            shift 2
            ;;
#        -c|--c-lunga)
#            case "$2" in
#                "") echo "Opzione c, senza argomenti" # debug
#                    shift 2
#                    ;;
#                *)  echo "Opzione c, argomento «$2»" # debug
#                    shift 2
#                    ;;
#            esac
#            ;;
				-S|--simulate) 
						SIMULATE="S"
						shift
						;;
				-N|--no-delete-user*)
						NODELUSER="S"
						shift
						;;
        --) shift
            break
            ;;
        *)  echo "Unpredictable error!"
            exit 1
            ;;
        esac
done

ARG_RESTANTI=()
for i in `seq 1 $#`
do
    eval a=\$$i
    ARG_RESTANTI[$i]="$a"
done

# [ "${#ARG_RESTANTI[*]}" -eq 0 ] && help "$PRG: ${COL_LTRED}ERRORE${COL_RESET}: pochi parametri!\n" 99

}



#############################################################
# INIZIO SCRIPT                                             #
#############################################################

# Trappiamo i segnali
for ac_signal in 1 2 13 15; do
  trap 'ac_signal='$ac_signal'; at_exit $ac_signal;' $ac_signal
done
ac_signal=0


#-- Valutazione dei parametri (argomenti - e --) e elborazione restanti - inizio
valuta_parametri "$@"
newparams=""
for i in `seq 1 ${#ARG_RESTANTI[*]}`
do
 newparams="$newparams '${ARG_RESTANTI[$i]}'"
done

eval "set -- $newparams"
# Ora li valuto normalmente come $1, $2, ... $n

### Da usare nel caso si vogliano imporre argomenti
# if [ -z "$1" ]; then
#	echo "$PRG: No argomenti?"
#	at_exit 99
#fi
#-- Valutazione dei parametri (argomenti - e --) e elborazione restanti - fine
MYID=`id -u`
[ $MYID -ne 0 ] && help "Error: $PRG : this script needs 'root' privileges (or you should use 'sudo')." 97

clear
echo "Try to guess Linux Distribution and release."
echo -ne " Please wait ..."
# Vediamo se c'è intanto il pacchetto LSB ...
DISTRO=
DISTROTEXT=
DISTROERR=
REL=
# DISTRO sarà uguale a 
#  RH  - Redhat/Centos/Fedora
#  DEB - Debian/Ubuntu/Mint etc.
#  SUS - SuSE Linux
#  ARC - ArchLinux
# ... per ora non altri
if [ -x /usr/bin/lsb_release ]; then
 lsbdescr=`lsb_release -a 2>/dev/null| grep ^Descr | cut -f2 -d: | sed "s/^\s*//" | sed "s/\s*$//"`

 case $lsbdescr in
	Debian*|Ubunt*|LMDE*)
		DISTRO=DEB
		DISTROTEXT="Debian based"
		;;
	RED*|Red*|Cent*|Fedo*|Scient*)
		DISTRO=RH
		DISTROTEXT="Redhat based"
		;;
	Arc*)
		DISTRO=ARC
		DISTROTEXT="Arch Linux"
		;;
	SuSE*)
		DISTRO=SUS
		DISTROTEXT="SuSE Linux"
		;;
	*)
		DISTROERR="LSB found, but unrecognized version."
		DISTROTEXT="Not recognized"
		;;
 esac

elif [ -f /etc/issue ]; then
	:
fi


## Fine indagine Linux
echo -ne "\r                    \r"

logga "Recognized version/distribution : $DISTROTEXT ($DISTRO)"


sino "Do I continue with process?" "N"
if [ $SINO = "Y" ]; then
:
	# Cominciamo con gli ALIAS
	ALIASNAME[0]='cd..'
	ALIASNAME[1]='..'
	ALIASNAME[2]='...'
	ALIASNAME[3]="ls"
	ALIASNAME[4]="l"
	ALIASNAME[5]="la"
	ALIASNAME[6]="lf"
	ALIASNAME[7]="lg"
	ALIASNAME[8]="ll"
	ALIASNAME[9]="ipa"
	ALIASNAME[10]="ipaddr"
	ALIASNAME[11]=""

	ALIASVALUE[0]='cd ..'
	ALIASVALUE[1]='cd ..'
	ALIASVALUE[2]='cd ../..'
	ALIASVALUE[3]='ls --color=auto'
	ALIASVALUE[4]='ls -alF'
	ALIASVALUE[5]='ls -lA'
	ALIASVALUE[6]='ls -CFA'
	ALIASVALUE[7]='ls -lAF --group-directories-first'
	ALIASVALUE[8]='ls -alF'
	ALIASVALUE[9]="ip -o addr show | grep inet\  | grep 'eth\|enp' | cut -d\  -f 7"
	ALIASVALUE[10]="ip -o addr show | grep inet\  | grep 'eth\|enp' | cut -d\  -f 7"
	ALIASVALUE[11]=""


	ESISTESKEL="N"
	if [ -f /etc/skel/.bash_aliases ]; then
		ESISTESKEL="S"
	fi

	case $DISTRO in
	DEB)
		ALIASINITFILE=/etc/bash.bashrc
		;;
	RH)
		ALIASINITFILE=/etc/profile.d/colorls.sh
		;;
	ARC)
		# GABODebug
		# echo "Fixme: al momento, non gestisco $DISTROTEXT, sorry"
		# at_exit 11
		ALIASINITFILE=/etc/bash.bashrc
		;;
	SUS)
		ALIASINITFILE=/etc/bash.bashrc
		;;
	*)
		# GABODebug
		echo "Fixme: incongruence."
		at_exit 11
		;;
	esac

###### CAN'T WORK in a bash script this one.. I've to grep $ALIASINITFILE or $SKELFILE
### 	# First, I load ALIASINITFILE in source, so to have alias in environment ...
### 	source $ALIASINITFILE
### 	giro=0
### 	TOT=0
### 	while [ -n "${ALIASNAME[$giro]}" ]
### 	do
### 		an=${ALIASNAME[$giro]}
### 		av=${ALIASVALUE[$giro]}
### 
### 		# Controllo di presenza alias in memoria nella SHELL corrente
### 		# (settato da qualcosa o qualcuno)
### 		res=$(alias $an 2>/dev/null)
### 		ret=$?
### 		if [ $ret -eq 0 ]; then
### 			echo -e "CAUTION: alias \"$an\" is currently assigned this way:"
### 			echo -e "   $res "
### 			echo -e "Confirming, it should be replaced by this:"
### 			echo -e "   alias ${an}='${av}'"
### 			echo ""
### 			sino "Ok to replace it?"
### 			[ "$SINO" = "N" ] && continue
### 		fi
### 
### 		# Controllo di presenza alias in ALIASINITFILE
### 		# --- DA IMPLEMENTARE (To implement yet)
### 
### 		echo "alias ${an}='${av}'" >> $ALIASINITFILE
### 		((giro++))
### 	done

 	giro=0
 	TOT=0
 	while [ -n "${ALIASNAME[$giro]}" ]
 	do
#		echo "giro = $giro" #GABODebug
 		an=${ALIASNAME[$giro]}
 		av=${ALIASVALUE[$giro]}
		an_esc=$(escapedot "$an")
 
		if (grep -q "^ *alias  *$an_esc *=" $ALIASINITFILE); then

#			echo "an = $an" #GABODebug
#			echo "an_esc = $an_esc" #GABODebug
			aaa=$(grep "^ *alias  *$an_esc *=" $ALIASINITFILE | tail -n1 | cut -f2- -d"=")
			res=$(trim "$aaa")

 			echo -e "CAUTION: alias \"$an\" is currently assigned this way:"
 			echo -e "   $res "
 			echo -e "Confirming, it should be replaced by this:"
 			echo -e "   alias ${an}='${av}'"
 			echo ""
 			sino "Ok to replace it?" "N"
 			[ "$SINO" = "N" ] && { ((giro++)); continue; }
 		fi
 
 		# Controllo di presenza alias in ALIASINITFILE
 		# --- DA IMPLEMENTARE (To implement yet)
 
 		echo "alias ${an}='${av}'" >> $ALIASINITFILE
 		((giro++))
 	done

###
## Prompt colorati
###
# PS1='[\[\e[1;31m\]\u@\h \w\[\e[m\]]\$ ' # PS1 root stile RedHat
### PS1='\[\e[1;31m\]${debian_chroot:+($debian_chroot)}\u@\h:\w\e[m\]\$ '  # PS1 root stile Debian
# PS1='\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[00;31m\]\w\[\033[00m\]\$ ' # PS1 root stile Debian
# PS1='\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ ' # PS1 user stile Debian



	# PS1 - ROOT stile Debian
	aps[0]='\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[00;31m\]\w\[\033[00m\]\$ '
	aps_disp[0]="\033[01;31mroot@hostname\033[00m:\033[00;31m/usr/local/bin\033[00m# "

	# PS1 - USER stile Debian
	aps[1]='\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[00;32m\]\u@\h\[\033[00m\]:\[\033[00;36m\]\w\[\033[00m\]\$ '
	aps_disp[1]="\033[00;32muser@hostname\033[00m:\033[00;36m/home/user/bin\033[00m$ "

	# PS1 - ROOT stile RedHat
	aps[2]='[\[\e[1;31m\]\u@\h \[\e[0;31m\]\w\[\e[m\]]\$ ' # PS1 root stile RedHat
	aps_disp[2]="[\e[1;31mroot@hostname \e[0;31m/usr/local/bin\e[m]# "

	# PS1 - USER stile RedHat
	aps[3]='[\[\e[1;32m\]\u@\h \[\e[0;34m\]\w\[\e[m\]]\$ ' # PS1 root stile RedHat
	aps_disp[3]="[\e[1;32muser@hostname \e[0;34m/usr/local/bin\e[m]$ "

	pscount=${#aps[@]}

	echo "Scelta prompt: "
	echo "+---+----------------------------------+----------------------------------+ "
	echo "| N |  Non-privileged user             |  ROOT user                       | "
	echo "+---+----------------------------------+----------------------------------+ "
	echo -e "  1    ${aps_disp[0]}     ${aps_disp[1]}   (Debian style) "
	echo -e "  2    ${aps_disp[2]}   ${aps_disp[3]} (Redhat style) "
	echo -e "  0                 ( System default - No colours ) "


	pschoose=""
	while ! [[ "$pschoose" =~ ^(1|2|0)$ ]]; do
		echo -ne "Scelta : "
		read pschoose
		# pschoose=$(echo $pschoose | sed "s/[\s\n\r]//g")
		echo
		if ! [[ "$pschoose" =~ ^(1|2|0)$ ]]; then
			echo " ERR: Please verify your choice. Accepted values: 0, 1, 2 "
		fi
	done

	
	if [ "$pschoose" -gt 0 ]; then
		psroot_id=$(((pschoose-1)*2))
		psuser_id=$((((pschoose-1)*2)+1))
		echo "psuser_id=$psuser_id"
		echo "psroot_id=$psroot_id"
		echo "if [ \"\$UID\" -eq 0 ]; then "	>> $ALIASINITFILE
		echo "  PS1='"${aps[$psroot_id]}"'" >> $ALIASINITFILE
		echo "else"	                        >> $ALIASINITFILE
		echo "  PS1='"${aps[$psuser_id]}"'"	>> $ALIASINITFILE
		echo "fi"	                        >> $ALIASINITFILE
				
		[ "$UID" -eq 0 ] && PS1="${aps[$psroot_id]}"  \
				 || PS1="${aps[$psuser_id]}"

	fi
	# Credo che la definizione del prompt debba diventare così:
	# # echo "ID is $UID"
	# # id -u
	# # logname
	# if [ "$UID" -eq 0 ]; then
	#         PS1='[\[\e[1;31m\]\u@\h \[\e[0;31m\]\w\[\e[m\]]\$ '
	# else
	#         PS1='[\[\e[1;32m\]\u@\h \[\e[0;34m\]\w\[\e[m\]]\$ '
	# fi



	# 
	# ORA FACCIO LE INSTALLAZIONI PREVISTE PER TIPO DI DISTRIBUZIONE
	case $DISTRO in
	DEB)
		apt-get update && apt-get upgrade \
			&& apt install aptitude apt-file htop mc mlocate vim openssh-server lsb-release\
					build-essential linux-headers-$(uname -r) module-assistant dkms
		sino "Have I to install needed packages for a LAMP system?" "N"
		if [ $SINO = "S" ]; then
			cat /etc/issue | grep -iq "Debian.* 9"
			[ $? -eq 0 ] && MYSQL_PKGS="mariadb-client mariadb-server" \
						 || MYSQL_PKGS="mysql-client mysql-server"
			
			apt-get install apache2 php $MYSQL_PKGS phpmyadmin
		fi
		sino "Do I install deb-multimedia" "N"
		if [ $SINO = "S" ]; then
			wget http://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb \
					-O /tmp/deb-multimedia-keyring_2016.8.1_all.deb
			sudo dpkg -i /tmp/deb-multimedia-keyring_2016.8.1_all.deb

			grep -q "deb-multimedia.org" /etc/apt/sources.list
			if [ $? -ne 0 ]; then
				echo "deb http://www.deb-multimedia.org stretch main non-free" >> /etc/apt/sources.list
				apt update
				apt -y upgrade
				apt -y install ffmpeg w64codecs
			fi

		fi
		;;
	RH)
		LC_ALL=C sudo yum -y groupinstall 'Development Tools'
		# yum -y install gcc gcc-c++ make openssl-devel kernel-devel
		sudo yum -y install openssl-devel wget curl

		# FIXME: This is good only for Enterprise Linux versions (CentOS, RHEL) ...
		lastdir=$(pwd)
		cd /tmp
		# CentOS 7 64
		## RHEL/CentOS 7 64-Bit ##
		wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-9.noarch.rpm
		sudo rpm -ivh epel-release-7-9.noarch.rpm
		## RHEL/CentOS 6 32-Bit ##
		# wget http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
		# rpm -ivh epel-release-6-8.noarch.rpm
		## RHEL/CentOS 6 64-Bit ##
		# wget http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
		# rpm -ivh epel-release-6-8.noarch.rpm
		sudo yum -y update
		sudo yum -y install htop mc mlocate vim openssh-server redhat-lsb dialog git
		;;
	ARC)
		sudo pacman -Syu
		sudo pacman -S base-devel bash-completion sudo linux-headers \
					make gcc vim lsb-release mc htop lshw mlocate
		sino "Have I to install needed packages for a LAMP system?" "N"
		if [ $SINO = "S" ]; then
			sudo pacman -S apache php php-apache phpmyadmin mariadb
		fi
		sino "Have I to install a minimal collection for a graphic environment (Xorg,DE)?" "N"
		if [ $SINO = "S" ]; then
			sudo pacman -S gdm xorg-xrandr libxrandr lxrandr libva-mesa-driver mesa mesa-libgl \
				mesa-libgl lightdm xorg-server xorg-xinit mesa xorg-twm xterm xorg-xclock cinnamon \
				nemo-fileroller fvwm fvwm-crystal cinnamon-desktop xorg-xauth xorg-server xterm \
				lightdm wayland mate-desktop S extra/xf86-video-amdgpu extra/xf86-video-ati \
				extra/xf86-video-dummy extra/xf86-video-fbdev extra/xf86-video-intel \
				extra/xf86-video-nouveau extra/xf86-video-openchrome extra/xf86-video-vesa extra/xf86-video-vmware \
				xorg-xinit
		fi
#  1) installerei pacaur (che è un pacman per AUR, davvero molto comodo, sebbene non sono sicuro ti serva a nulla)
# 3) https://wiki.archlinux.org/index.php/Codecs qui ci sta la lista codec, anche se io in genere uso GStreamer e mi salvo

#    systemctl enable dhcpcd
#    systemctl enable sshd
#    systemctl start sshd
#    useradd gabo -m
#    passwd gabo
#    vi /etc/group
#    vi /etc/group
#    groupadd -g 27 sudo
#    usermod gabo -G sudo -a
#    visudo
#   vi rc.conf
#   vim /etc/dhcpcd.conf 
#   cd /usr/bin/
#   mv vi vi.old
#   ln -s vim vi

		;;
	SUS)
		;;
	*)
		;;
	esac





else
at_exit 99
fi
echo

at_exit 0
