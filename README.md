# Winlux

Um Linux leve e rápido para seu terminal.

## Instalação

A partir de uma máquina Ubuntu ou Debian, execute esta única linha para baixar o repositório e instalar os arquivos e dependências:

```bash
git clone https://github.com/guirgb/Winlux.git && cd Winlux && sudo bash install.sh
```

O instalador `install.sh`:

- instala as ferramentas básicas (`git`, `curl`, certificados e compilador);
- instala Python e as dependências de `requirements.txt`, se esse arquivo existir;
- instala Node.js/npm e as dependências de `package.json`, se esse arquivo existir;
- copia os arquivos para `/opt/winlux`;
- cria o comando global `winlux` em `/usr/local/bin/winlux`.

O script pode ser executado novamente sem precisar remover a instalação. Para usar outro diretório de destino:

```bash
sudo WINLUX_INSTALL_DIR=/caminho/do/destino bash install.sh
```

> O projeto atualmente contém a base do repositório e o instalador. Quando os arquivos da aplicação forem adicionados, as dependências correspondentes serão instaladas automaticamente de acordo com `requirements.txt` ou `package.json`.
