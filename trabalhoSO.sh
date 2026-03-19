#!/bin/bash

arq_aux=$(mktemp)
trap 'rm -f "$arq_aux"' EXIT

info_cpu()
{
	dialog --title "Detalhes do processador" --msgbox "$(lscpu)" 20 60
}

info_disp_arm()
{
	dialog --title "Dispositivos de armazenamento" --msgbox "$(lsblk)" 20 60
}

info_mem()
{
	dialog --title "Detalhes do uso da memória" --msgbox "$(free -h)" 10 60
}

info_redes()
{
	dialog --title "Status das conexões de rede" --msgbox "$(nmcli d)" 10 60
}

menu_info_sist()
{
	dialog --clear \
	--title "Informações do sistema" \
	--menu "Escolha uma opção:" 15 70 5 \
	"1" "Exibir detalhes do processador" \
	"2" "Exibir detalhes sobre dispositivos de armazenamento" \
	"3" "Exibir informações sobre uso da memória" \
	"4" "Exibir status das conexões de rede" \
	"5" "Retornar" \
	2> opInfoSist.txt
}

opcao_info_sist() {
	opcao_info=$(cat opInfoSist.txt)
	case $opcao_info in
		1) info_cpu ;;
		2) info_disp_arm ;;
		3) info_mem ;;
		4) info_redes ;;
		5) return ;;
		*) dialog --msgbox "Opção inválida." 10 50 ;;
	esac
}

disp_interface()
{
	dialog --menu "O que deseja fazer?" 15 50 2 \
	"1" "Ativar interface (up)" \
	"2" "Desativar interface (down)" \
	2> opInter.txt
	
	opInter=$(cat opInter.txt)
	case $opInter in
		1)
			dialog --inputbox "Digite o nome da interface de rede:" 10 50 2>interface.txt
			interface=$(cat interface.txt)
			ifconfig "$interface" up
			if [ -s interface.txt ]; then
				dialog --msgbox "Interface ativada." 10 50 
			fi
			rm -f interface.txt ;;
		2)
			dialog --inputbox "Digite o nome da interface de rede:" 10 50 2>interface.txt
			interface=$(cat interface.txt)
			ifconfig "$interface" down
			if [ -s interface.txt ]; then
				dialog --msgbox "Interface desativada" 10 50 
			fi
			rm -f interface.txt ;;
	esac
}

carregar_modulo()
{
	dialog --inputbox "Digite o nome do módulo:" 10 50 2>modulo.txt
	modulo=$(cat modulo.txt)
	modprobe "$modulo"
	if [ -s modulo.txt ]; then
		dialog --msgbox "Módulo carregado." 10 50
	fi
	rm -f modulo.txt
}

remover_modulo()
{
	dialog --inputbox "Digite o nome do módulo:" 10 50 2>modulo.txt
	modulo2=$(cat modulo.txt)
	/sbin/rmmod "$modulo2"
	if [ -s modulo.txt ]; then
		dialog --msgbox "Módulo removido." 10 50
	fi
	rm -f modulo.txt
}

listar_disp()
{
	dialog --title "Lista de dispositivos PCI" --msgbox "$(lspci)" 10 60
}

menu_disp_onboard()
{
	dialog --clear \
	--title "Gerenciamento de dispositivos Onboard" \
	--menu "Escolha uma opção:" 15 70 5 \
	"1" "Configurar interface de rede" \
	"2" "Carregar módulo do kernel" \
	"3" "Remover módulo do kernel" \
	"4" "Listar dispositivos PCI" \
	"5" "Retornar" \
	2> opDisp.txt
}

opcao_disp_onboard() {
	opcao_disp=$(cat opDisp.txt)
	case $opcao_disp in
		1) disp_interface ;;
		2) carregar_modulo ;;
		3) remover_modulo ;;
		4) listar_disp ;;
		5) return ;;
		*) dialog --msgbox "Opção inválida." 10 50 ;;
	esac
}

monitorar_recursos()
{
	> "$arq_aux"

	(
		while true; do
			top -bn1 | head -n 20 >> "$arq_aux"
			sleep 1
		done
	)&
	
	dialog --title "Monitor de processos e recursos" --tailbox "$arq_aux" 20 70
	
	kill $! 2>/dev/null
	rm -f "$arq_aux"
	
}

monitorar_energia()
{
	dialog --title "Monitor de energia e resfriamento" --msgbox "$(acpi -V)" 10 60
}

monitorar_maquina()
{
    > "$arq_aux"

    (
        while true; do
             glances --stdout cpu,mem,load,disk,network,sensors,process > "$arq_aux"
            sleep 1
        done
    ) &

    dialog --title "Monitor da máquina" --tailbox "$arq_aux" 20 70
    

    kill $! 2>/dev/null #finalizar o loop em segundo plano ou assim q fecha o dialog??
    rm -f "$arq_aux"
}

monitorar_disco()
{
	> "$arq_aux"
	
	(
		while true; do
			dstat --disk --nocolor >> "$arq_aux"
			sleep 1
		done
	)&
	
	dialog --title "Monitor de Disco(I/O)" --tailbox "$arq_aux" 20 70

	
	kill $! 2>/dev/null
	rm -f "$arq_aux"
}

menu_moni_hardware()
{
	dialog --clear \
	--title "Monitoramento do hardware em tempo real" \
	--menu "Escolha uma opção:" 15 70 5 \
	"1" "Processos e uso de recursos" \
	"2" "Energia e Resfriamento" \
	"3" "Monitorar máquina" \
	"4" "Monitorar disco (I/O)" \
	"5" "Retornar" \
	2> opHard.txt
}

opcao_moni_hardware() {
	opcao_hard=$(cat opHard.txt)
	case $opcao_hard in
		1) monitorar_recursos ;;	#htop
		2) monitorar_energia ;;
		3) monitorar_maquina ;;
		4) monitorar_disco ;;		#dstat --disk
		5) return ;;
		*) dialog --msgbox "Opção inválida." 10 50 ;;
	esac
}

config_sudo()
{
	dialog --clear \
	--title "Configurar permissão para usuário" \
	--menu "Deseja:" 15 70 3 \
	"1" "Permitir todos os comandos usando senha" \
	"2" "Permitir todos os comandos sem usar senha" \
	"3" "Permitir somente alguns comandos" \
	2>opSudo.txt
	
	opSudo=$(cat opSudo.txt)
	
		dialog --inputbox "Nome do usuário a ser configurado:" 10 50 2>usuario.txt
	usuario=$(cat usuario.txt)
	
	case $opSudo in
		1) echo "$usuario ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers ;;
		2) echo "$usuario ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers ;;
		3) dialog --inputbox "Digite os comandos que deseja permitir(entre ',')" 10 50 2>comandos.txt
		   comandos=$(cat comandos.txt)
		   echo "$usuario ALL=(ALL:ALL) NOPASSWD: $comandos" | sudo tee -a /etc/sudoers ;;
	esac
}

usuarios_logados()
{
	dialog --title "Lista de usuários" --msgbox "$(who)" 10 60
}

historico_login()
{
	dialog --title "Histórico de logins" --msgbox "$(last)" 10 70
}

atividade_usuarios()
{
	aureport -u > relatorio_usuarios.txt
    	dialog --title "Relatório de auditoria de usuários" --textbox relatorio_usuarios.txt 20 100
    	rm -f relatorio_usuarios.txt
}
menu_config_seg()
{
	dialog --clear \
	--title "Configurações de segurança" \
	--menu "Escolha uma opção:" 15 70 5 \
	"1" "Editar sudoers (sudo)" \
	"2" "Usuários logados no sistema" \
	"3" "Historico de logins" \
	"4" "Atividades por usuário" \
	"5" "Retornar" \
	2> opSeg.txt
}

opcao_config_seg()
{
	opcao_seg=$(cat opSeg.txt)
	case $opcao_seg in
		1) config_sudo ;;	#como se fosse o visudo tee -a /etc/sudoers	
		2) usuarios_logados ;;	#who
		3) historico_login ;;	#last
		4) atividade_usuarios ;; #aureport -u		
		5) return ;;
		*) dialog --msgbox "Opção inválida." 10 50 ;;
	esac
}

ajustar_DataHora()
{
	dialog --inputbox "Digite a data e o horaŕio na forma (ano-mes-dia hh:mm:ss):" 10 50 2> dataHora.txt
	troca=$(cat dataHora.txt)
	sudo date -s "$troca"
	dialog --msgbox "Data definida para: $troca" 10 60
}

fuso_horario()
{
	dialog --inputbox "Digite o fuso-horário:" 10 50 2>fuso.txt
	fuso=$(cat fuso.txt)
	sudo timedatectl set-timezone "$fuso"
	dialog --msgbox "Fuso definido: $fuso" 10 60
}

exibir_rtc()
{
	hwclock_path=$(which hwclock 2>/dev/null || find / -name hwclock 2>/dev/null | grep -m 1 hwclock)
	if [ -z "$hwclock_path" ]; then
        	dialog --msgbox "Erro: hwclock não encontrado no sistema." 10 50
        	 return 1
    	fi
	rtc_time=$($hwclock_path --show 2>/dev/null)
    	dialog --title "Relógio de Hardware (RTC):" --msgbox "$rtc_time" 10 50
}

historico()
{
	dialog --title "Histórico de alteração" --msgbox "$(journalctl | grep 'timedatectl\|hwclock' | cut -d' ' -f1-5,12-)" 10 60
}

menu_config_DataHora()
{
	dialog --clear \
	--title "Configurações de Data e Hora" \
	--menu "Escolha uma opção:" 15 70 5 \
	"1" "Ajustar data e hora" \
	"2" "Definir fuso-horário" \
	"3" "Relógio de Hardware(RTC)" \
	"4" "Histórico de alteração de data, hora e fuso-horário" \
	"5" "Retornar" \
	2> opDH.txt
}

opcao_config_DataHora()
{
	opcao_DH=$(cat opDH.txt)
	case $opcao_DH in
		1) ajustar_DataHora ;;		
		2) fuso_horario ;;	
		3) exibir_rtc ;;	
		4) historico ;; 	
		5) return ;;
		*) dialog --msgbox "Opção inválida." 10 50 ;;
	esac
}

gcc_compiler()
{
	find . -type f -name "*.c" | awk '{sub(/^\.\//, ""); print}' > arquivosC.txt
	mapfile -t listaArquivos < arquivosC.txt
	
	if [[ ${#listaArquivos[@]} -eq 0 ]]; then
		dialog --msgbox "Não existem arquivos .c" 10 50
		return
	fi
	
	dialog --inputbox "Nome do arquivo a ser compilado('nome.c'):\n$(printf "%s\n" "${listaArquivos[@]}")" 10 50 2>escolhaC.txt
	escolhaC=$(cat escolhaC.txt)
	
	gcc "$escolhaC" -o "${escolhaC%.c}.exe" 2> erroCompilacao.log
	
	if [[ $? -eq 0 ]]; then
		dialog --inputbox "Arquivo compilado. Entre com o nome para o arquivo de log:" 10 50 2>nomeLog.txt
		nomeLog=$(cat nomeLog.txt)
		
		saida_temp=$(mktemp)
		./"${escolhaC%.c}.exe" | tee "$nomeLog" > "$saida_temp"
		
		dialog --title "Saída(salva em: $nomeLog):" --textbox "$saida_temp" 10 50
		
		rm -f "$saida_temp"
	else
		erros=$(erroCompilacao.log)
		dialog --msgbox "Erro ao compilar: \n$erros" 10 50
	fi
	
}

menu_principal()
{
	dialog --clear --backtitle "Trabalho Final SO"\
	--title "Menu" \
	--menu "Escolha uma opção:" 15 50 5 \
	"1" "Informações do sistema" \
	"2" "Gerenciar dispositivos Onboard" \
	"3" "Monitorar hardware em tempo real" \
	"4" "Configurações de Segurança" \
	"5" "Configurações de Data e Hora" \
	"6" "Compilar e executar códigos em C" \
	"7" "Sair" \
	2> escolha.txt
}

escolha_principal()
{
	opcao=$(cat escolha.txt)
	case $opcao in
	1) 
		while true; do
			menu_info_sist
			opcao_info_sist
			[ "$(cat opInfoSist.txt)" = "5" ] && break
		done ;;
	2)
		while true; do
			menu_disp_onboard
			opcao_disp_onboard
			[ "$(cat opDisp.txt)" = "5" ] && break
			
		done ;;
	3)
		while true; do
			menu_moni_hardware
			opcao_moni_hardware
			[ "$(cat opHard.txt)" = "5" ] && break
		done ;;
	4)
		while true; do
			menu_config_seg
			opcao_config_seg
			[ "$(cat opSeg.txt)" = "5" ] && break
		done ;;
	5)
		while true; do
			menu_config_DataHora
			opcao_config_DataHora
			[ "$(cat opDH.txt)" = "5" ] && break
		done ;;
	6) gcc_compiler ;;
	7)
		clear
		exit 0 ;;
	esac

}

#executa o script feito acima
while true; do
    menu_principal
    escolha_principal
done
