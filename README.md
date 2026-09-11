# Winlux

Um Linux leve e rápido para seu terminal.

## Instalação

A partir do Termux, execute esta linha, sem usar `sudo`:

```bash
git clone https://github.com/guirgb/Winlux.git && cd Winlux && bash install.sh
```

No Ubuntu ou Debian, use:

```bash
git clone https://github.com/guirgb/Winlux.git && cd Winlux && sudo bash install.sh
```

O instalador `install.sh`:

- instala as ferramentas básicas (`git`, `curl`, certificados e compilador);
- instala Python e as dependências de `requirements.txt`, se esse arquivo existir;
- instala Node.js/npm e as dependências de `package.json`, se esse arquivo existir;
- copia os arquivos para `/opt/winlux` no Ubuntu/Debian ou `$PREFIX/opt/winlux` no Termux;
- cria o comando `winlux` em `/usr/local/bin/winlux` no Ubuntu/Debian ou `$PREFIX/bin/winlux` no Termux.

O script pode ser executado novamente sem precisar remover a instalação. Para usar outro diretório de destino:

```bash
sudo WINLUX_INSTALL_DIR=/caminho/do/destino bash install.sh
```

> O projeto atualmente contém a base do repositório e o instalador. Quando os arquivos da aplicação forem adicionados, as dependências correspondentes serão instaladas automaticamente de acordo com `requirements.txt` ou `package.json`.
