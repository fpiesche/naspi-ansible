include env

.EXPORT_ALL_VARIABLES:

unmount_device:
	test -n "$(NASPI_DEVICE)"
	sudo umount -f $(NASPI_DEVICE)1 || true
	sudo umount -f $(NASPI_DEVICE)2 || true

raspios_usb: unmount_device
	test -n "$(NASPI_DEVICE)"
	echo "Writing image to $(NASPI_DEVICE)..."
	curl -sL "$(RASPIOS_IMAGE)" | xz -d | sudo dd of=$(NASPI_DEVICE) status=progress
	echo "Enabling SSH..."
	mkdir -p .tmpmount
	sudo mount -t vfat -o users,uid=1000,gid=1000,umask=0000,rw $(NASPI_DEVICE)1 .tmpmount
	sudo touch .tmpmount/ssh
	sudo cp userconf .tmpmount/
	sudo umount .tmpmount
	rmdir .tmpmount

virtualenv:
	test -d "venv" || python3 -m virtualenv venv
	bash -c "source venv/bin/activate && python3 -m pip install ansible==5.10.0 mitogen"

deploy: virtualenv
	bash -c "source venv/bin/activate && ansible-galaxy install -f -r requirements.yml"
	bash -c "source venv/bin/activate && ansible-playbook --ask-vault-password -i hosts.yml playbook.yml"
 