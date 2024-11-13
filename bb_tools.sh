#!/bin/bash


#------------------------ Prompt for sudo password ----------------------------------#

sudo -v


#------------------------ Colors ----------------------------------#

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
END='\e[0m'


#------------------------ Global Variables ----------------------------------#

tools_dir=~/tools
tool=""
category=""
log_file=""
store=""


#------------------------ Python Virtual Environment ----------------------------------#

python_venv()
{
    [[ -d ${tools_dir}/myenv ]] || python3 -m venv ${tools_dir}/myenv
    source ~/tools/myenv/bin/activate
}


#------------------------ Log File ----------------------------------#

get_log_file()
{
    tool=$1
    log_file="${store}/${1}.log"
}


#------------------------ Display message before installation ----------------------------------#

msg_before_install()
{
    local msg="${CYAN}[$category]${YELLOW} Installing $tool"
    local cursors=('/' '-' '\' '|')

    while kill -0 $! > /dev/null 2>&1 ; do
        for curs in "${cursors[@]}"; do
            echo -ne "\r${msg} $curs"
            sleep 0.1
        done
    done
}


#------------------------ Display message after installation ----------------------------------#

msg_after_install()
{
    if [ $1 -eq 0 ]; then
        echo -e "\r${CYAN}[$category]${GREEN} $tool was installed successfully!"
    else
        echo -e "\r${CYAN}[$category]${RED} $tool was not installed successfully!"
    fi
    echo -e $END
}


#------------------------ Display full message ----------------------------------#

msg_install()
{
    msg_before_install
    wait $!
    msg_after_install $?
}


#------------------------ Initialize ----------------------------------#

script_init()
{
    export PATH=$PATH:/usr/local/go/bin:~/.local/go/bin:~/tools/myenv/bin
    store=$(mktemp -d)
    mkdir ${tools_dir} -p
}


#------------------------ Initialising category ----------------------------------#

init_category() 
{
    category=$1
    echo -e "${YELLOW}=================================================================================================="
    echo -e "${MAGENTA}                                    INSTALLING ${category} TOOLS"
    echo -e "${YELLOW}=================================================================================================="
    echo -e $END
}


#------------------------ Install tools with apt-get ----------------------------------#

apt_tool()
{
    get_log_file $1

    sudo apt-get install -y $1 > $log_file 2>&1 &

    msg_install
}


#------------------------ Install go tools ----------------------------------#

go_tool()
{
    get_log_file $1
    
    go install $2 > $log_file 2>&1 &

    msg_install
}


#------------------------ Installing essential tools ----------------------------------#

install_essential()
{
    sudo apt-get update

    local tools=(zip unzip whois libpcap-dev git make gcc pip net-tools curl python3-venv python-is-python3)
    init_category "Essential-Tools"

    for tool in "${tools[@]}"; do
        apt_tool $tool
    done

    # Installing go

    get_log_file "go"

    (
        set -e
        wget "https://go.dev/dl/go1.23.0.linux-amd64.tar.gz" -O golang.tar.gz
        sudo tar -C /usr/local -xzf golang.tar.gz
        rm golang.tar.gz
        go env -w GOPATH=~/.local/go
    ) > "$log_file" 2>&1 &

    msg_install
}


#------------------------ Installing Subdomain Enumeration Tools ----------------------------------#

tool_subfinder()
{
    go_tool "subfinder" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
}

tool_amass()
{
    go_tool "amass" "github.com/owasp-amass/amass/v4/...@master"
}


#------------------------ Installing HTTP Probing Tools ----------------------------------#

tool_httpx()
{
    go_tool "httpx" "github.com/projectdiscovery/httpx/cmd/httpx@latest"
}


#------------------------ Installing Screenshot Tools ----------------------------------#

tool_eyewitness()
{
    get_log_file "eyewitness"

    (
        set -e
        sudo rm -rf ${tools_dir}/EyeWitness
        git clone "https://github.com/RedSiege/EyeWitness.git" ${tools_dir}/EyeWitness
        cd ${tools_dir}/EyeWitness/Python/setup
        sudo bash setup.sh

        # Adding these lines manually, because the sudo command is picking up the system-wide python & pip binary
        pip3 install --upgrade pip
        python3 -m pip install -r requirements.txt

        cd

    ) > $log_file 2>&1 &

    msg_install
}


#------------------------ Installing Directory Bruteforcing Tools ----------------------------------#

tool_ffuf()
{
    apt_tool "ffuf"
}

tool_dirsearch()
{
    get_log_file "dirsearch"

    (
        set -u
        git clone https://github.com/maurosoria/dirsearch.git --depth 1 ${tools_dir}/dirsearch > $log_file 2>&1 &
        cd ${tools_dir}/dirsearch 
        pip install -r requirements.txt
        cd
    ) > $log_file 2>&1 &

    msg_install
}



#------------------------ Installing Port Scanning Tools ----------------------------------#

tool_nmap()
{
    apt_tool "nmap"
}

tool_naabu()
{
    go_tool "naabu" "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
}


#------------------------ Installing Vulnerability Scanners ----------------------------------#

tool_nuclei()
{
    go_tool "nuclei" "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
}


#------------------------ Installing Web Crawling Tools ----------------------------------#

tool_katana()
{
    go_tool "katana" "github.com/projectdiscovery/katana/cmd/katana@latest"
}

tool_getJS()
{
    go_tool "getJS" "github.com/003random/getJS/v2@latest"
}

tool_gau()
{
    go_tool "gau" "github.com/lc/gau/v2/cmd/gau@latest"
}

tool_waybackurls()
{
    go_tool "waybackurls" "github.com/tomnomnom/waybackurls@latest"
}


#------------------------ Installing Secrets Discovery Tools ----------------------------------#

tool_mantra()
{
    go_tool "mantra" "github.com/MrEmpy/mantra@latest"
}

tool_trufflehog()
{
    get_log_file "trufflehog"

    (
        set -e
        curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh -o install.sh
        chmod +x install.sh 
        sudo ./install.sh -b /usr/local/bin
        rm -r install.sh
    ) > $log_file 2>&1 &

    msg_install
}

tool_githound()
{
    get_log_file "githound"

    (
        set -u
        wget "https://github.com/tillson/git-hound/releases/download/v1.7.2/git-hound_1.7.2_linux_amd64.tar.gz" -O githound.tar.gz
        rm -rf ~/githound ~/.githound && mkdir ~/githound ~/.githound
        wget "https://raw.githubusercontent.com/tillson/git-hound/refs/heads/main/config.example.yml" -O ~/.githound/config.yml
        tar -xzf githound.tar.gz -C ~/githound && rm -rf githound.tar.gz
        mv ~/githound/git-hound ~/.local/bin && rm -rf ~/githound
    ) > $log_file 2>&1 &

    msg_install
}


#------------------------ Installing Misconfiguration Scanner Tools ----------------------------------#

tool_s3scanner()
{
    go_tool "s3scanner" "github.com/sa7mon/s3scanner@latest"
}


#------------------------ Installing HTTP Parameter Discovery Tools ----------------------------------#

tool_arjun()
{
    get_log_file "arjun"

    (
        set -e
        pip install pipx
        pipx install arjun
    ) > $log_file 2>&1 &

    msg_install
}


#------------------------ Installing OS Command Injection Exploitation Tools ----------------------------------#

tool_commix()
{
    get_log_file "commix"

    (
        set -e
        sudo rm -rf ${tools_dir}/commix
        git clone "https://github.com/commixproject/commix.git" ${tools_dir}/commix
        cd ${tools_dir}/commix
        sudo python3 commix.py --install
        cd
    ) > $log_file 2>&1 &

    msg_install
}


#------------------------ Installing Local File Inclusion Exploitation Tools ----------------------------------#

tool_lfimap()
{
    get_log_file "lfimap"

    pip install lfimap > $log_file 2>&1 &

    msg_install
}


#------------------------ All categories functions ----------------------------------#

install_sub-enum()
{
    init_category "Subdomain-Enumeration"

    tool_subfinder
    tool_amass
}

install_http-probing()
{
    init_category "HTTP-Probing"

    tool_httpx
}

install_ss()
{
    init_category "Screenshot"

    tool_eyewitness
}

install_web-crawler()
{
    init_category "Web-Crawler"

    tool_katana
    tool_getJS
    tool_gau
    tool_waybackurls
}

install_dir-brute()
{
    init_category "Directory-Bruteforcer"

    tool_ffuf
    tool_dirsearch
}

install_secrets-discovery()
{
    init_category "Secrets-Discovery"

    tool_mantra
    tool_trufflehog
    tool_githound
}

install_misconfig-scanner()
{
    init_category "Misconfiguration-Scanner"

    tool_s3scanner
}

install_port-scanner()
{
    init_category "Port-Scanner"

    tool_nmap
    tool_naabu
}

install_vuln-scanner()
{
    init_category "Vulnerability-Scanner"
    
    tool_nuclei
}

install_command-injection()
{
    init_category "OS-Command-Injection-Exploitation"

    tool_commix
}

install_lfi()
{
    init_category "Local-File-Inclusion-Exploitation"

    tool_lfimap
}

install_http-param-discovery()
{
    init_category "HTTP-Parameter-Discovery"

    tool_arjun
}

#------------------------ Installing all tools ----------------------------------#

install_all()
{
    for func in $(compgen -A function install_); do
        [[ "$func" == "install_essential" || "$func" == "install_all" ]] || $func
    done
}


#------------------------ Show Banner ----------------------------------#

show_banner()
{
    echo "   ___           _           _     __ _            _   _     "
    echo "  / _ \_ __ ___ (_) ___  ___| |_  / _\ | ___ _   _| |_| |__  "
    echo " / /_)/ '__/ _ \| |/ _ \/ __| __| \ \| |/ _ \ | | | __| '_ \ "
    echo "/ ___/| | | (_) | |  __/ (__| |_  _\ \ |  __/ |_| | |_| | | |"
    echo "\/    |_|  \___// |\___|\___|\__| \__/_|\___|\__,_|\__|_| |_|"
    echo "              |__/                                           "
    echo "                                                             "
    echo "                                                             "
}


#------------------------ Show Help ----------------------------------#

show_help()
{
    echo -e "${YELLOW}Usage: $0 [options]${END}"
    echo "Options:"
    echo "  --all                           All tools (including essential)"
    echo "  --essential                     Essential tools"
    echo "  --sub-enum                      Subdomain enumeration tools"
    echo "  --http-probing                  HTTP Probing tools"
    echo "  --ss                            Screenshotting tools"
    echo "  --dir-brute                     Directory Bruteforcing tools"
    echo "  --port-scanner                  Port Scanning tools"
    echo "  --vuln-scanner                  Vulnerability Scanning tools"
    echo "  --web-crawler                   Web Crawling tools"
    echo "  --http-param-discovery          HTTP Parameter Discovery tools"
    echo "  --secrets-discovery             Secret Discovery tools"
    echo "  --misconfig-scanner             Misconfiguration Scanner tools"
    echo "  --command-injection             OS Command Injection Exploitation tools"
    echo "  --lfi                           Local File Inclusion Exploitation tools"
    echo "  --skip-essential                Skip Essential tools"
    echo "  --help                          Show this help message"
    echo ""
    echo -e "${RED}WARNING:${END} This script should not be run with sudo priveleges."
    echo -e "${YELLOW}Note:${END} Installing any set of tools will also install essential tools by default."
    echo -e "${YELLOW}Note:${END} To ensure correct installation of all tools, please install essential tools first."
    echo ""
}


#------------------------ Final Message ----------------------------------#

show_final_msg()
{
    if ! grep -qxF 'export PATH=$PATH:/usr/local/go/bin:~/.local/go/bin' ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin:~/.local/go/bin' >> ~/.bashrc
    fi

    if ! grep -qxF "export PATH=\$PATH:${tools_dir}/myenv/bin" ~/.bashrc; then
        echo "export PATH=\$PATH:${tools_dir}/myenv/bin" >> ~/.bashrc
    fi

    if ! grep -qxF 'export PATH=$PATH:~/.local/bin' ~/.bashrc; then
        echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
    fi
    
    echo -e "${YELLOW}[+-+-+] Installation complete. Please run ${GREEN}'source ~/.bashrc'${END}"
    echo -e "${YELLOW}[+-+-+] GOPATH is set to ${GREEN}~/.local/go"
    echo -e "${YELLOW}[+-+-+] Tools and Python Virtual Environment are installed in ${GREEN}${tools_dir}"
    echo -e "${YELLOW}[+-+-+] Update tool config files before running."
    echo -e "${YELLOW}[+-+-+] For logs, navigate to ${GREEN}${store}"
    echo -e $END
}


#------------------------ Main ----------------------------------#

main()
{
    show_banner
    sleep 1
    
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    if [ $EUID -eq 0 ]; then
        echo -e "${RED}The script should not be run with sudo. Try running without it.${END}"
        exit 1
    fi


    skip_essential=false
    all=false
    categories=()

    for arg in "$@"; do

        func="${arg//--/}"

        if [[ $func == "skip-essential" ]]; then
            skip_essential=true
        elif [[ $func == "help" ]]; then
            show_help
            exit 0
        elif ! declare -f install_${func} > /dev/null; then
            echo -e "${RED}Invalid option: $arg${END}"
            sleep 1
            show_help
            exit 1
        elif [[ $func != "essential" ]]; then
            if [[ $func == "all" ]]; then
                categories=("all")
                all=true   
            elif [[ $all == "false" ]]; then
                categories+=($func)
            fi
        fi
    done

    [[ $skip_essential == false ]] && script_init && install_essential

    python_venv

    if [ ${#categories[@]} -gt 0 ]; then
        script_init
        
        for func in "${categories[@]}"; do
            install_${func}
        done
    fi

    deactivate

    show_final_msg
}

main "$@"