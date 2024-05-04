#!/bin/bash
function addfirewall() {
    # MEMILIH CHAIN
    echo ""
    echo "Chain Firewall yang digunakan?"
    echo "  1) INPUT"
    echo "  2) OUTPUT"
    echo "  3) FORWARD"
    read -p "Option: " chain
    until [[ "$chain" =~ ^[1-3]$ ]]; do
	    echo "$chain: invalid selection."
	    read -p "Option: " chain
    done
    case "$chain" in
        1) chain="INPUT";;
        2) chain="OUTPUT";;
        3) chain="FORWARD";;
    esac

    # MEMILIH SOURCE ADDRESS
    echo ""
    echo "Source Address:"
    echo "  1) Menggunakan Satu Source IP Address"
    echo "  2) Menggunakan Subnet Source IP Address"
    echo "  3) Menggunakan Semua Sources Network/IP Address"
    read -p "Option: " srcip
    until [[ "$srcip" =~ ^[1-3]$ ]]; do
        echo "$srcip: invalid selection"
        read -p "Option: " srcip
    done
    case "$srcip" in
        1) 
            echo ""
            read -p "Masukkan Source IP Address (contoh: 192.168.1.10): " srcip
        ;;
        2)
            echo ""
            read -p "Masukkan Source Subnet IP Address (contoh: 192.168.1.0/24): " srcip
        ;;
        3) srcip="0/0" 
        ;;
    esac

    # MEMILIH DESTINATION ADDRESS
    echo ""
    echo "Destination Address:"
    echo "  1) Menggunakan Satu Destination IP Address"
    echo "  2) Menggunakan Subnet Destination IP Address"
    echo "  3) Menggunakan Semua Destination Network/IP Address"
    read -p "Option: " dstip
    until [[ "$dstip" =~ ^[1-3]$ ]]; do
        echo "$dstip: invalid selection"
        read -p "Option: " dstip
    done
    case "$dstip" in
        1)
            echo ""
            read -p "Masukkan Destination IP Address (contoh: 192.168.1.10): " dstip
        ;;
        2)
            echo ""
            read -p "Masukkan Subnet Destination IP Address (contoh: 192.168.1.0/24): " dstip
        ;;
        3) dstip="0/0"
        ;;
    esac

    # MEMILIH PORT
    echo ""
    read -p "Apakah anda ingin memblokir port? [y/N]: " port
    until [[ "$port" =~ ^[yYnN]*$ ]]; do
        echo "$port: invalid selection."
        read -p "Apakah anda ingin memblokir port? [y/N]: " port
    done
    if [[ "$port" =~ ^[Yy]$ ]]; then
        echo ""
        read -p "Masukkan Port yang ingin anda blokir (contoh: 22): " port
        # MEMILIH PROTOCOL PORT
        echo ""
        echo "Protocol apa yang digunakan port tersebut?"
        echo "  1) TCP"
        echo "  2) UDP"
        read -p "Option: " protocol
        until [[ "$protocol" =~ ^[1-2]$ ]]; do
            echo "$protocol: invalid selection."
            read -p "Option: " protocol
        done
        case "$protocol" in
            1) protocol="tcp";;
            2) protocol="udp";;
        esac
    else
        port="NULL"
    fi

    # MEMILIH PROTOCOL
    if [ "$port" == "NULL" ]; then
        echo ""
        echo "Menggunakan Protocol:"
        echo "  1) TCP"
        echo "  2) UDP"
        echo "  3) Keduanya (TCP & UDP)"
        read -p "Option: " protocol
        until [[ "$protocol" =~ ^[1-3]$ ]]; do
            echo "$protocol: invalid selection."
            read -p "Option: " protocol
        done
        case "$protocol" in
            1) protocol="tcp";;
            2) protocol="udp";;
            3) protocol="all";;
        esac
    else
        protocol="$protocol"
    fi

    # MEMILIH ACTION
    echo ""
    echo "Apa yang akan Dilakukan untuk Aturan Firewall ini?"
    echo "  1) ACCEPT -> Paket akan diizinkan untuk melewati firewall tanpa ada tindakan tambahan"
    echo "  2) DROP -> Paket akan diabaikan, dan sumbernya tidak akan menerima informasi apapun tentang penolakan tersebut"
    echo "  3) REJECT -> Paket akan ditolak, dan pengirim akan menerima pesan penolakan"
    read -p "Option: " action
    until [[ "$action" =~ ^[1-3]$ ]]; do
        echo "$action: invalid selection."
        read -p "Option: " action
    done
    case "$action" in
        1) action="ACCEPT";;
        2) action="DROP";;
        3) action="REJECT";;
    esac

    # BUILD FIREWALL SCRIPT
    echo ""
    echo "generate firewall rules"
    if [ "$port" == "NULL" ]; then
        tables="iptables -A $chain -s $srcip -d $dstip -p $protocol -j $action"
    else
        tables="iptables -A $chain -s $srcip -d $dstip -p $protocol --dport $port -j $action"
    fi
    echo "$tables"

    # MEMASUKKAN FIREWALL RULES KE TABEL
    echo ""
    read -p "Apakah kamu ingin memasukkan rule tersebut ke dalam firewall tabel? [y/N]: " enterrules
    until [[ "$enterrules" =~ ^[yYnN]*$ ]]; do
        echo "$enterrules: invalid selection."
        read -p "Apakah kamu ingin memasukkan rule tersebut ke dalam firewall tabel? [y/N]: " enterrules
    done
    if [[ "$enterrules" =~ ^[yY]$ ]]; then
        $tables
        echo ""
        echo "Rules Firewall berhasil ditambahkan. Cek menggunakan command (iptables -L $chain)"
    else
        exit
    fi
}

function deletefirewall() {
    # MENENTUKAN CHAIN FIREWALL
    echo ""
    echo "Rules Firewall yang ingin dihapus berada di Chain?"
    echo "  1) INPUT"
    echo "  2) OUTPUT"
    echo "  3) FORWARD"
    read -p "Option: " chain
    until [[ "$chain" =~ ^[1-3]$ ]]; do
	    echo "$chain: invalid selection."
	    read -p "Option: " chain
    done
    case "$chain" in
        1) chain="INPUT";;
        2) chain="OUTPUT";;
        3) chain="FORWARD";;
    esac
    iptables -L "$chain" --line-number
    echo ""
    read -p "Masukkan nomor aturan yang ingin dihapus: " nomor

    # VALIDASI
    iptables -L "$chain" --line-number | awk '{print $1}' | grep -w "$nomor" >/dev/null
    exit_code=$?

    until [ $exit_code -eq 0 ]; do
        echo "Tidak ada aturan dengan nomor tersebut."
        read -p "Masukkan nomor aturan yang ingin dihapus: " nomor

        iptables -L "$chain" --line-number | awk '{print $1}' | grep -w "$nomor" >/dev/null
        exit_code=$?
    done
    echo "Nomor aturan yang dimasukkan pengguna benar."
    echo ""
    iptables -L "$chain" --line-number | awk "NR==$nomor+2"
    read -p "Apakah anda ingin menghapus aturan diatas?[y/N]: " remove
    until [[ "$remove" =~ ^[yYnN]*$ ]]; do
        echo "$remove: invalid selection."
        read -p "Apakah anda ingin menghapus aturan diatas?[y/N]: " remove
    done
    if [[ "$remove" =~ ^[yY]$ ]]; then
        iptables -D "$chain" "$nomor"
        echo ""
        echo "Rules Firewall berhasil di hapus."
    else
        exit
    fi
}

function listfirewall() {
    # MENENTUKAN CHAIN FIREWALL
    echo ""
    echo "Chain Firewall yang ingin dilihat?"
    echo "  1) INPUT"
    echo "  2) OUTPUT"
    echo "  3) FORWARD"
    echo "  4) ALL"
    read -p "Option: " chain
    until [[ "$chain" =~ ^[1-4]$ ]]; do
	    echo "$chain: invalid selection."
	    read -p "Option: " chain
    done
    case "$chain" in
        1) chain="INPUT";;
        2) chain="OUTPUT";;
        3) chain="FORWARD";;
        4) chain="NULL";;
    esac
    if [ "$chain" == "NULL" ]; then
        iptables -L
    else
        iptables -L "$chain"
    fi
}

function flushfirewall() {
    echo ""
    read -p "Apakah anda benar-benar ingin menghapus semua rules firewall?[y\N]: " option
    until [[ "$option" =~ ^[yYnN]*$ ]]; do
        echo "$option: invalid selection."
        read -p "Apakah anda benar-benar ingin menghapus semua rules firewall?[y\N]: " option
    done
    if [[ "$option" =~ ^[yY]$ ]]; then
        iptables -F
        echo ""
        echo "Rules Firewall berhasil di hapus."
    else
        exit
    fi
}

function internet() {
    echo ""
    read -p "Apakah anda yakin ingin mengatur / connect internet dengan mengatur mikrotik menggunakan script?[y/N]: " option
    until [[ "$option" =~ ^[yYnN]*$ ]]; do
        echo "$option: invalid selection."
        read -p "Apakah anda yakin ingin mengatur / connect internet dengan mengatur mikrotik menggunakan script?[y/N]: " option
    done
    if [[ "$option" =~ ^[yY]$ ]]; then
        echo ""
        echo "Check Dependencies"
        if ! apt list --installed | grep sshpass > /dev/null; then
            sudo apt-get install sshpass -y > /dev/null
        fi
        echo "OK!"
        echo ""
        read -p "IP dari Mikrorik: " ip 
        read -p "User untuk Login Mikrotik: " username
        read -sp "Password untuk Login Mikrotik: " password
        echo ""
        read -p "ether yang terhubung ke sumber internet (contoh: ether1): " ether
        sshpass -p $password ssh $username@$ip "/ip/dhcp-client/add interface=$ether"
        echo ""
        echo "Berhasil Terkoneksi dengan Internet"
    else
        exit
    fi
}

function main() {
ROOT_UID=0
if [ $UID == $ROOT_UID ];
then
clear
echo "What Should I Do?"
echo
echo "Select an options:"
echo "  1) Add Rules Firewall"
echo "  2) Delete Rules Firewall"
echo "  3) List Rules Firewall"
echo "  4) Flush Firewall Rules (**Gunakan dengan hati-hati ini akan menghapus semua rules dari iptables**)"
echo "  5) Connect to Internet (Optional & Not Recommended)"
echo "  6) Exit"
read -p "Option: " input
until [[ "$input" =~ ^[1-5]$ ]]; do
	echo "$input: invalid selection."
	read -p "Option: " input
done
case "$input" in
    1) addfirewall;;
    2) deletefirewall;;
    3) listfirewall;;
    4) flushfirewall;;
    5) internet;;
    6) exit;;
esac
else
    echo "You Must be the ROOT to Running this Script!!!"
fi
}

main