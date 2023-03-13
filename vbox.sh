#!/bin/bash

add_virtual_machine(){
  read -p "Qual o nome da maquina: " machine_name
  read -p "Tipo do sistema operacional: " os_type
  read -p "Quantidade de ram a ser usada: " qtd_ram
  read -p "Qual a porta VRDE a ser usada: " vrde_port
  read -p "Qual o tamanho do disco em GB: " qtd_disk
  read -p "Quantos processadores pretende usar: " qtd_cpus
  read -p "Digite o nome da interface de rede que essa maquina irá usar: " iface
  echo "Escolha a ISO a ser usada para a instalação: "

  IFS=$'\n'
  isos=($(ls -1 /virt/isos/))
  for i in "${!isos[@]}"
  do
    echo "${i}. ${isos[i]}"
  done

  read iso

  echo "Usando a imagem: /virt/isos/${isos[${iso}]}"

  echo "Vamos criar a maquina virtual com o nome: ${machine_name}
  Porta de acesso VRDE(RDP): ${vrde_port}
  Tipo de os: ${os_type}
  Quantidade de Ram: ${qtd_ram} MB
  Cpus: ${qtd_cpus} 
  Disco: ${qtd_disk} MB
  Network interface: ${iface}"

  sudo vboxmanage createvm --name "${machine_name}" --ostype "${os_type}" --register --basefolder /vms
  echo "Criando a maquina virtual"
  sleep 3
  sudo vboxmanage modifyvm "${machine_name}" --cpus "${qtd_cpus}" --memory "${qtd_ram}" --vram 128 --boot1 dvd --boot2 disk
  echo "Adicionando as CPUS"
  sleep 3
  sudo vboxmanage storagectl "${machine_name}" --name "disk" --add sata --portcount 2 --bootable on
  echo "Adicionando discos"
  sleep 3
  sudo vboxmanage modifyvm "${machine_name}" --nic1 bridged --bridgeadapter1 "${iface}" --cableconnected1 on --nicpromisc1 deny
  echo "Configurando interface de rede"
  sleep 3
  sudo vboxmanage modifyvm "${machine_name}" --vrde on --vrdeport "${vrde_port}"
  echo "Configurando acesso VRDE"
  sleep 3
  sudo mkdir -p /virt/vms/"${machine_name}"
  echo "Adicionando pasta maquina virtual no endereço"
  sleep 3
  sudo vboxmanage createmedium --filename /virt/vms/"${machine_name}"/disk1.vdi --size "${qtd_disk}" --format vdi
  echo "Criando HD no local selecionado"
  sleep 3
  sudo vboxmanage storageattach "${machine_name}" --storagectl "disk" --port 0 --type hdd --medium /virt/vms/"${machine_name}"/disk1.vdi --mtype normal
  echo "Conectando hd na maquina"
  sleep 3
  sudo vboxmanage storageattach "${machine_name}" --storagectl "disk" --port 1 --type dvddrive --medium /virt/isos/"${isos[${iso}]}"
  echo "Conectando iso no drive"
  sleep 3

  start_virtual_machine "${machine_name}"
}

del_virtual_machine(){
  read -p "Qual o nome da maquina que você deseja remover: " machine_name

  sudo vboxmanage unregistervm "${machine_name}" --delete
  sudo rm -rf /virt/vms/"${machine_name}"
}

start_virtual_machine(){
  machine=$1
  sudo vboxmanage startvm "${machine}" --type headless
  local IFS=$"\n"
  vrde_port=($(sudo vboxmanage showvminfo "${machine}" | grep -i "vrde port"))
  echo "${vrde_port[*]}"
}

stop_virtual_machine(){
  machine=$1
  sudo vboxmanage controlvm "${machine}" poweroff
}

menu(){
  echo "1. Para adicionar maquina virtual "
  echo "2. Para deletar maquina virtual "
  echo "3. Para iniciar uma maquina virtual "
  echo "4. Para desligar uma maquina virtual "
  read opcao 

  case "${opcao}" in
    1)
      add_virtual_machine
      ;;
    2)
      del_virtual_machine
      ;;
    3)
      read -p "Digite nome da maquina virtual: " machine_name
      start_virtual_machine "${machine_name}"
      ;;
    4)
      read -p "Digite o nome da maquina virtual: " machine_name
      stop_virtual_machine "${machine_name}"
      ;;
    *)
      menu
      ;;
  esac
}

menu
