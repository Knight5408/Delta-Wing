// Importa a biblioteca de som do Processing
import processing.sound.*;

// ============================================================
//  DELTA WING - Jogo de Ação 2D estilo retrô
//  Nostalgia Game Studio
//  Desenvolvido em Processing (Java)
//  Vista de cima — oceano embaixo, nuvens passando
// ============================================================

// ---------- CONSTANTES DE ESTADO DO JOGO ----------
// Cada constante representa uma "tela" diferente do jogo.
// A variável gameState controla qual tela está ativa no momento.
final int STATE_MENU       = 0; // Tela do menu principal
final int STATE_SCORES     = 1; // Tela de melhores pontuações
final int STATE_PLAYING    = 2; // Jogo em andamento
final int STATE_PAUSED     = 3; // Jogo pausado
final int STATE_GAMEOVER   = 4; // Tela de fim de jogo
final int STATE_NAME_ENTRY = 5; // Tela para digitar o nome no ranking

int gameState = STATE_MENU;     // Começa no menu principal

// ---------- PONTUAÇÃO, VIDAS E WAVES ----------
int   score         = 0;    // Pontuação atual do jogador
int   lives         = 3;    // Vidas restantes (começa com 3)
int   wave          = 1;    // Número da wave (onda) atual
float waveTimer     = 0;    // Tempo decorrido na wave atual (em segundos)
float spawnInterval = 3.0;  // Intervalo (segundos) entre aparições de inimigos
int   maxEnemies    = 3;    // Máximo de inimigos simultâneos na tela

// ---------- RANKING TOP 5 ----------
String[] topNames  = new String[5]; // Nomes dos jogadores no ranking
int[]    topScores = new int[5];    // Pontuações correspondentes
String   nameBuffer = "";           // Texto sendo digitado na tela de nome

// ---------- PONTOS PERDIDOS (feedback visual) ----------
// Quando um inimigo escapa, um texto flutuante aparece mostrando a penalidade.
// Cada entrada: [x, y, pontos_perdidos, timer_de_vida]
ArrayList<float[]> scorePenalties = new ArrayList<float[]>();
final int ESCAPE_PENALTY = 50; // Pontos descontados por inimigo que escapar

// ---------- JOGADOR ----------
float px, py;               // Posição X e Y do jato do jogador
float pSpeed    = 4.5;      // Velocidade de movimento do jogador
boolean[] keys  = new boolean[526]; // Array que registra quais teclas estão pressionadas
int shootCooldown = 0;      // Contador que impede o jogador de atirar muito rápido
int hitFlash      = 0;      // Contador para o efeito visual de piscar ao tomar dano
int invincible    = 0;      // Contador de frames de invencibilidade após tomar dano

// ---------- PROJÉTEIS DO JOGADOR ----------
// Cada projétil é um array [x, y] — posição atual na tela
ArrayList<float[]> bullets = new ArrayList<float[]>();

// ---------- INIMIGOS NORMAIS ----------
// Lista de todos os inimigos ativos no momento
ArrayList<Enemy> enemies = new ArrayList<Enemy>();
float spawnAccum = 0; // Acumulador de tempo para controlar o spawn de inimigos

// ---------- BOSS ----------
Boss boss            = null;  // Referência ao boss atual (null se não houver boss ativo)
boolean bossWave     = false; // true quando a wave atual é de boss
boolean bossDefeated = false; // true quando o boss foi derrotado nesta wave

// ---------- PROJÉTEIS DOS INIMIGOS ----------
// Cada projétil inimigo é um array [x, y, vx, vy] — posição e velocidade
ArrayList<float[]> eBullets = new ArrayList<float[]>();

// ---------- PARTÍCULAS DE EXPLOSÃO ----------
// Lista de partículas ativas (geradas nas explosões)
ArrayList<Particle> particles = new ArrayList<Particle>();

// ---------- FUNDO — OCEANO ----------
float oceanScroll = 0; // Controla o deslocamento vertical do efeito de oceano

// ---------- NUVENS ----------
// Cada nuvem é um array [x, y, escala, velocidade]
float[][] clouds = new float[10][4];

// ---------- SPRITES PNG ----------
// Imagens dos jatos carregadas da pasta data/
PImage imgPlayer; // Sprite do jato do jogador
PImage imgEnemy;  // Sprite dos jatos inimigos
PImage imgBoss;   // Sprite do boss

// ---------- SONS ----------
// Efeitos sonoros carregados da pasta data/
SoundFile somTiroPlayer;   // Som do tiro do jogador
SoundFile somTiroInimigo;  // Som do tiro dos inimigos e boss
SoundFile somMorteInimigo; // Som de explosão de inimigo normal
SoundFile somDanoPlayer;   // Som de dano ao jogador (ainda tem vidas)
SoundFile somMortePlayer;  // Som de morte do jogador (game over)
SoundFile somMorteBoss;    // Som de explosão do boss
SoundFile musicaJogo;      // Música de fundo durante a partida

// ============================================================
//  SETUP — executado UMA vez ao iniciar o programa
// ============================================================
void setup() {
  size(800, 600); // Define o tamanho da janela do jogo

  // Define a fonte padrão usada em todos os textos do jogo
  textFont(createFont("Courier New Bold", 16, true));

  // Carrega os sprites PNG da pasta data/ do projeto
  imgPlayer = loadImage("Player.png");
  imgEnemy  = loadImage("Inimigo.png");
  imgBoss   = loadImage("Boss.png");

  // Carrega os arquivos de som da pasta data/ do projeto
  somTiroPlayer   = new SoundFile(this, "TiroPlayer.wav");
  somTiroInimigo  = new SoundFile(this, "TiroInimigo.wav");
  somMorteInimigo = new SoundFile(this, "MorteInimigo.wav");
  somDanoPlayer   = new SoundFile(this, "DanoNoPlayer.wav");
  somMortePlayer  = new SoundFile(this, "MortePlayer.wav");
  somMorteBoss    = new SoundFile(this, "MorteBoss.wav");
  musicaJogo      = new SoundFile(this, "musicaDeltaWing.wav");

  // Inicializa as estruturas de dados do jogo
  initScores(); // Zera o ranking
  initClouds(); // Posiciona as nuvens iniciais
  initGame();   // Reseta todos os estados para uma nova partida
}

// ============================================================
//  INIT — funções de inicialização/reset
// ============================================================

// Reseta todos os estados para o início de uma nova partida
void initGame() {
  px = width / 2;      // Jogador começa no centro horizontal
  py = height - 110;   // Jogador começa próximo à parte inferior da tela
  lives         = 3;   // 3 vidas
  score         = 0;   // Pontuação zerada
  wave          = 1;   // Começa na wave 1
  waveTimer     = 0;
  spawnInterval = 3.0;
  maxEnemies    = 3;
  spawnAccum    = 0;
  bossWave      = false;
  bossDefeated  = false;
  boss          = null;
  enemies.clear();      // Remove todos os inimigos
  bullets.clear();      // Remove todos os projéteis do jogador
  eBullets.clear();     // Remove todos os projéteis inimigos
  particles.clear();    // Remove todas as partículas de explosão
  scorePenalties.clear(); // Remove todos os textos de penalidade flutuantes
  shootCooldown = 0;
  invincible    = 0;
  hitFlash      = 0;
}

// Inicializa as nuvens com posições, escalas e velocidades aleatórias
void initClouds() {
  for (int i = 0; i < clouds.length; i++) {
    clouds[i][0] = random(width);        // Posição X aleatória
    clouds[i][1] = random(-40, height);  // Posição Y aleatória (pode começar fora da tela)
    clouds[i][2] = random(0.7, 1.8);     // Escala aleatória
    clouds[i][3] = random(1.2, 2.5);     // Velocidade aleatória
  }
}

// Inicializa o ranking com valores padrão
void initScores() {
  for (int i = 0; i < 5; i++) {
    topNames[i]  = "---";
    topScores[i] = 0;
  }
}

// ============================================================
//  DRAW — loop principal, executado ~60 vezes por segundo
// ============================================================
void draw() {
  // Direciona para a função de desenho correta conforme o estado atual
  switch (gameState) {
    case STATE_MENU:       drawMenu();      break;
    case STATE_SCORES:     drawScores();    break;
    case STATE_PLAYING:    drawPlaying();   break;
    case STATE_PAUSED:     drawPaused();    break;
    case STATE_GAMEOVER:   drawGameOver();  break;
    case STATE_NAME_ENTRY: drawNameEntry(); break;
  }
}

// ============================================================
//  TELA: MENU PRINCIPAL
// ============================================================
void drawMenu() {
  drawOceanBackground(false); // Fundo de oceano estático
  drawClouds(false);          // Nuvens estáticas

  // Painel semi-transparente por trás do título
  fill(0, 0, 0, 150);
  noStroke();
  rect(width/2 - 310, 88, 620, 118, 12);

  // Título do jogo
  fill(255, 220, 0);
  textAlign(CENTER, CENTER);
  textSize(62);
  text("DELTA WING", width/2, 138);

  // Subtítulo
  fill(180, 220, 255);
  textSize(15);
  text("AIR SUPERIORITY COMBAT  |  TOP-DOWN SHOOTER", width/2, 186);

  // Sprite do jogador centralizado como decoração do menu
  drawPlayerJet(width/2, 310, 2.6, 255);

  // Botões do menu
  drawButton("[ JOGAR ]",           width/2, 420, isMouseOnBtn(width/2, 420));
  drawButton("[ MELHORES SCORES ]", width/2, 485, isMouseOnBtn(width/2, 485));

  // Instruções de controle no rodapé
  fill(70, 100, 160);
  textSize(11);
  text("SETAS = mover  |  ESPACO = atirar  |  P = pausar", width/2, 575);
}

// ============================================================
//  TELA: MELHORES SCORES (TOP 5)
// ============================================================
void drawScores() {
  drawOceanBackground(false);
  drawClouds(false);

  fill(0, 0, 0, 165);
  noStroke();
  rect(width/2 - 280, 58, 560, 432, 12);

  fill(255, 220, 0);
  textAlign(CENTER, CENTER);
  textSize(44);
  text("TOP 5 SCORES", width/2, 108);

  // Exibe cada entrada do ranking com cor diferente para os 3 primeiros
  textSize(20);
  for (int i = 0; i < 5; i++) {
    color c;
    if      (i == 0) c = color(255, 215, 0);   // Ouro
    else if (i == 1) c = color(192, 192, 192); // Prata
    else if (i == 2) c = color(205, 127, 50);  // Bronze
    else              c = color(160, 190, 255); // Azul para os demais
    fill(c);
    text((i+1) + ".  " + topNames[i] + "   " + nf(topScores[i], 6), width/2, 194 + i * 58);
  }

  drawButton("[ VOLTAR ]", width/2, 510, isMouseOnBtn(width/2, 510));
}

// ============================================================
//  TELA: JOGO EM ANDAMENTO
// ============================================================
void drawPlaying() {
  drawOceanBackground(true); // Fundo animado (oceano rolando)
  drawClouds(true);          // Nuvens se movendo

  // Atualiza a lógica do jogo (ordem importa)
  updateWave();    // Controla a progressão das waves e boss
  updatePlayer();  // Processa movimento e tiro do jogador
  updateBullets(); // Move projéteis do jogador e verifica colisões
  if (bossWave && boss != null) updateBoss();   // Lógica do boss
  else                          updateEnemies(); // Lógica dos inimigos normais
  updateEBullets();   // Move projéteis inimigos e verifica colisões com jogador
  updateParticles();  // Atualiza partículas de explosão
  updateScorePenalties(); // Atualiza os textos flutuantes de penalidade

  // Desenha todos os elementos na tela (ordem define sobreposição)
  drawParticles();  // Explosões (atrás de tudo)
  drawEBullets();   // Projéteis inimigos
  if (bossWave && boss != null) drawBoss();   // Boss
  else                          drawEnemies(); // Inimigos normais
  drawBullets();    // Projéteis do jogador
  drawPlayer();     // Jato do jogador
  drawScorePenalties(); // Textos flutuantes de pontos perdidos
  drawHUD();        // Interface (score, vidas, wave, barra do boss)
}

// ============================================================
//  TELA: JOGO PAUSADO
// ============================================================
void drawPaused() {
  // Renderiza o estado atual do jogo congelado atrás do overlay
  drawOceanBackground(false);
  drawClouds(false);
  drawParticles();
  drawEBullets();
  if (bossWave && boss != null) drawBoss();
  else drawEnemies();
  drawBullets();
  drawPlayer();
  drawHUD();

  // Overlay escuro semi-transparente sobre o jogo
  fill(0, 0, 0, 175);
  noStroke();
  rect(0, 0, width, height);

  fill(255, 220, 0);
  textAlign(CENTER, CENTER);
  textSize(56);
  text("PAUSADO", width/2, 220);

  drawButton("[ RETOMAR ]",         width/2, 330, isMouseOnBtn(width/2, 330));
  drawButton("[ SAIR DA PARTIDA ]", width/2, 400, isMouseOnBtn(width/2, 400));
}

// ============================================================
//  TELA: GAME OVER
// ============================================================
void drawGameOver() {
  drawOceanBackground(false);
  drawClouds(false);

  fill(0, 0, 0, 165);
  noStroke();
  rect(width/2 - 282, 118, 564, 374, 12);

  fill(220, 30, 30);
  textAlign(CENTER, CENTER);
  textSize(68);
  text("GAME OVER", width/2, 188);

  // Exibe a pontuação final e a wave alcançada
  fill(255, 255, 255);
  textSize(26);
  text("SCORE: " + nf(score, 6), width/2, 262);

  fill(180, 210, 255);
  textSize(16);
  text("WAVE ALCANCADA: " + wave, width/2, 302);

  drawButton("[ SALVAR SCORE ]",    width/2, 368, isMouseOnBtn(width/2, 368));
  drawButton("[ JOGAR NOVAMENTE ]", width/2, 428, isMouseOnBtn(width/2, 428));
  drawButton("[ MENU PRINCIPAL ]",  width/2, 488, isMouseOnBtn(width/2, 488));
}

// ============================================================
//  TELA: ENTRADA DE NOME PARA O RANKING
// ============================================================
void drawNameEntry() {
  drawOceanBackground(false);
  drawClouds(false);

  fill(0, 0, 0, 165);
  noStroke();
  rect(width/2 - 242, 128, 484, 312, 12);

  fill(255, 220, 0);
  textAlign(CENTER, CENTER);
  textSize(38);
  text("NOVO RECORDE!", width/2, 183);

  fill(255);
  textSize(22);
  text("Score: " + nf(score, 6), width/2, 243);

  fill(180, 210, 255);
  textSize(16);
  text("Digite seu nome (ate 8 letras):", width/2, 283);

  // Caixa de texto para o nome
  stroke(255, 220, 0);
  strokeWeight(2);
  noFill();
  rect(width/2 - 120, 304, 240, 48, 6);
  noStroke();

  // Nome digitado com cursor piscante
  fill(255, 220, 0);
  textSize(26);
  text(nameBuffer + (frameCount % 30 < 15 ? "|" : ""), width/2, 330);

  fill(140, 165, 215);
  textSize(13);
  text("ENTER = confirmar  |  BACKSPACE = apagar", width/2, 398);
}

// ============================================================
//  UPDATE: PROGRESSÃO DE WAVES
// ============================================================
void updateWave() {
  // Durante uma wave de boss, o timer NÃO avança.
  // O boss precisa ser derrotado para a wave avançar.
  if (!bossWave) {
    waveTimer += 1.0 / frameRate;
  }

  // Wave normal termina após 20 segundos
  boolean timeUp = (!bossWave && waveTimer > 20.0);

  // Wave de boss termina APENAS quando bossDefeated for marcado true
  boolean bossCleared = (bossWave && bossDefeated);

  if (timeUp || bossCleared) {
    waveTimer    = 0;
    spawnAccum   = 0;
    bossDefeated = false;

    // Incrementa a wave apenas se não foi wave de boss
    if (!bossWave) wave++;

    // A cada múltiplo de 5 waves, inicia uma wave de boss
    if (wave % 5 == 0 && !bossWave) {
      bossWave = true;
      enemies.clear();  // Remove inimigos normais durante o boss
      eBullets.clear();
      // HP do boss aumenta a cada ciclo de 5 waves
      int bossHp = 40 + (wave / 5) * 20;
      boss = new Boss(bossHp);
    } else {
      // Wave normal: ajusta dificuldade progressivamente
      bossWave = false;
      boss     = null;
      spawnInterval = max(0.8, 3.0 - wave * 0.15); // Intervalo mínimo de 0.8s
      maxEnemies    = min(10, 3 + wave);            // Máximo de 10 inimigos simultâneos
    }
  }
}

// ============================================================
//  UPDATE: JOGADOR
// ============================================================
void updatePlayer() {
  // Movimento nas quatro direções com as setas do teclado
  if (keys[LEFT]  && px > 30)           px -= pSpeed;
  if (keys[RIGHT] && px < width - 30)   px += pSpeed;
  if (keys[UP]    && py > 40)           py -= pSpeed;
  if (keys[DOWN]  && py < height - 30)  py += pSpeed;

  // Tiro com a barra de espaço (shootCooldown evita spam)
  if (shootCooldown > 0) shootCooldown--;
  if (keys[32] && shootCooldown == 0) {
    // Dois projéteis saem levemente afastados (um de cada asa)
    bullets.add(new float[]{px - 11, py - 18});
    bullets.add(new float[]{px + 11, py - 18});
    shootCooldown = 12; // Aguarda 12 frames antes de permitir novo tiro
    somTiroPlayer.stop();
    somTiroPlayer.play();
  }

  // Decrementa contadores de invencibilidade e flash de dano
  if (invincible > 0) invincible--;
  if (hitFlash  > 0) hitFlash--;
}

// ============================================================
//  UPDATE: PROJÉTEIS DO JOGADOR
// ============================================================
void updateBullets() {
  for (int i = bullets.size() - 1; i >= 0; i--) {
    float[] b = bullets.get(i);
    b[1] -= 10; // Move o projétil para cima (Y decresce)

    // Remove se saiu da tela pelo topo
    if (b[1] < -10) { bullets.remove(i); continue; }

    boolean hit = false;

    // Verifica colisão com cada inimigo normal
    for (int j = enemies.size() - 1; j >= 0; j--) {
      Enemy e = enemies.get(j);
      if (dist(b[0], b[1], e.x, e.y) < 22) { // Raio de colisão de 22px
        explode(e.x, e.y, e.col);  // Cria explosão na posição do inimigo
        enemies.remove(j);          // Remove o inimigo
        bullets.remove(i);          // Remove o projétil
        score += 100 + wave * 10;  // Pontuação aumenta conforme a wave
        somMorteInimigo.stop();
        somMorteInimigo.play();
        hit = true;
        break;
      }
    }
    if (hit) continue;

    // Verifica colisão com o boss (se estiver ativo)
    if (bossWave && boss != null) {
      if (dist(b[0], b[1], boss.x, boss.y) < boss.radius) {
        boss.hp--;  // Reduz HP do boss
        explode(b[0], b[1], color(255, 200, 0)); // Faísca no ponto de impacto
        bullets.remove(i);

        // Verifica se o boss morreu
        if (boss.hp <= 0) {
          // Três explosões em posições diferentes para efeito dramático
          explode(boss.x,      boss.y,      color(255, 100, 0));
          explode(boss.x - 25, boss.y + 15, color(255,  60, 0));
          explode(boss.x + 25, boss.y - 15, color(200, 200, 0));
          score += 1000 + wave * 50; // Grande bônus de pontos pelo boss
          somMorteBoss.stop();
          somMorteBoss.play();
          boss         = null;
          bossDefeated = true;  // Sinaliza para updateWave() avançar
          bossWave     = false;
          wave++;
          spawnInterval = max(0.8, 3.0 - wave * 0.15);
          maxEnemies    = min(10, 3 + wave);
          waveTimer     = 0;
        }
      }
    }
  }
}

// ============================================================
//  UPDATE: INIMIGOS NORMAIS
// ============================================================
void updateEnemies() {
  // Controla o spawn: adiciona um inimigo quando o intervalo for atingido
  spawnAccum += 1.0 / frameRate;
  if (spawnAccum >= spawnInterval && enemies.size() < maxEnemies) {
    spawnAccum = 0;
    enemies.add(new Enemy());
  }

  // Velocidade base de descida aumenta com a wave
  float baseSpeed = 1.5 + wave * 0.12;

  for (int i = enemies.size() - 1; i >= 0; i--) {
    Enemy e = enemies.get(i);
    e.update(baseSpeed); // Atualiza posição do inimigo (movimento lateral + descida)

    // Chance de atirar a cada frame — aumenta com a wave
    if (random(1) < 0.018 + wave * 0.002) {
      float spd = 4.0 + wave * 0.08; // Velocidade do projétil aumenta com a wave
      eBullets.add(new float[]{e.x, e.y, 0, spd, 0}); // tipo=0: tiro de inimigo normal
      somTiroInimigo.stop();
      somTiroInimigo.play();
    }

    // Colisão corpo-a-corpo: inimigo encosta no jogador
    if (invincible == 0 && dist(e.x, e.y, px, py) < 26) {
      explode(e.x, e.y, e.col);
      enemies.remove(i);
      lives--;
      hitFlash   = 22;
      invincible = 90; // 90 frames (~1.5s) de invencibilidade após o dano
      explode(px, py, color(255, 100, 0));
      somMorteInimigo.stop();
      somMorteInimigo.play();
      if (lives <= 0) {
        somMortePlayer.stop();
        somMortePlayer.play();
        musicaJogo.stop();
        gameState = STATE_GAMEOVER;
      } else {
        somDanoPlayer.stop();
        somDanoPlayer.play();
      }
      continue;
    }

    // Inimigo passou da tela sem ser destruído: penalidade de pontos
    if (e.y > height + 50) {
      enemies.remove(i);
      // Desconta pontos (mínimo 0, score nunca fica negativo)
      int penalty = ESCAPE_PENALTY;
      score = max(0, score - penalty);
      // Adiciona texto flutuante de penalidade no ponto onde o inimigo saiu
      // Array: [x, y, pontos, timer]
      scorePenalties.add(new float[]{e.x, height - 20, penalty, 90});
    }
  }
}

// ============================================================
//  UPDATE: BOSS
// ============================================================
void updateBoss() {
  if (boss == null) return;
  boss.update(); // Move o boss (entrada e oscilação lateral)

  // Colisão corpo-a-corpo: jogador encosta no boss
  if (invincible == 0 && dist(px, py, boss.x, boss.y) < boss.radius + 18) {
    lives--;
    hitFlash   = 22;
    invincible = 90;
    explode(px, py, color(255, 100, 0));
    if (lives <= 0) {
      somMortePlayer.stop();
      somMortePlayer.play();
      musicaJogo.stop();
      gameState = STATE_GAMEOVER;
    } else {
      somDanoPlayer.stop();
      somDanoPlayer.play();
    }
  }

  // Boss atira em leque de 3 projéteis apontando para o jogador
  if (random(1) < 0.022 + wave * 0.002) {
    for (int k = -1; k <= 1; k++) {
      // Calcula ângulo em direção ao jogador com leve variação para cada tiro
      float ang = atan2(py - boss.y, px - boss.x) + k * 0.22;
      float spd = 3.0;
      // tipo=1 identifica projéteis do boss (desenho circular)
      eBullets.add(new float[]{
        boss.x, boss.y + boss.radius * 0.5,
        cos(ang)*spd, sin(ang)*spd, 1
      });
    }
    // Usa o mesmo som de tiro dos inimigos normais para o boss
    somTiroInimigo.stop();
    somTiroInimigo.play();
  }
}

// ============================================================
//  UPDATE: PROJÉTEIS DOS INIMIGOS
// ============================================================
void updateEBullets() {
  for (int i = eBullets.size() - 1; i >= 0; i--) {
    float[] b = eBullets.get(i);
    b[0] += b[2]; // Move horizontalmente (vx)
    b[1] += b[3]; // Move verticalmente (vy)

    // Remove se saiu dos limites da tela
    if (b[0] < -10 || b[0] > width+10 || b[1] < -10 || b[1] > height+10) {
      eBullets.remove(i); continue;
    }

    // Colisão com o jogador (se não estiver invencível)
    if (invincible == 0 && dist(b[0], b[1], px, py) < 18) {
      eBullets.remove(i);
      lives--;
      hitFlash   = 22;
      invincible = 90;
      explode(px, py, color(255, 100, 0));
      if (lives <= 0) {
        somMortePlayer.stop();
        somMortePlayer.play();
        musicaJogo.stop();
        gameState = STATE_GAMEOVER;
      } else {
        somDanoPlayer.stop();
        somDanoPlayer.play();
      }
    }
  }
}

// ============================================================
//  UPDATE: PARTÍCULAS DE EXPLOSÃO
// ============================================================
void updateParticles() {
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    if (p.isDead()) particles.remove(i); // Remove partículas que expiraram
  }
}

// ============================================================
//  UPDATE: TEXTOS FLUTUANTES DE PENALIDADE
// ============================================================
void updateScorePenalties() {
  for (int i = scorePenalties.size() - 1; i >= 0; i--) {
    float[] sp = scorePenalties.get(i);
    sp[1] -= 0.8; // Sobe lentamente pela tela
    sp[3]--;      // Decrementa o timer de vida
    if (sp[3] <= 0) scorePenalties.remove(i); // Remove quando o timer zerar
  }
}

// ============================================================
//  FUNDO: OCEANO VISTO DE CIMA
// ============================================================
void drawOceanBackground(boolean moving) {
  background(8, 55, 110); // Cor base azul-marinho do oceano

  // Avança o scroll quando o jogo está em movimento
  if (moving) oceanScroll += 2.0;
  if (oceanScroll > 60) oceanScroll -= 60; // Reinicia o ciclo de scroll

  noStroke();

  // Faixas de corrente oceânica que rolam para baixo
  for (int i = 0; i < 12; i++) {
    float yy = ((i * 55 + oceanScroll * 2.5) % (height + 60)) - 30;
    float ww = random(width * 0.25, width * 0.65);
    float xx = noise(i * 3.7, frameCount * 0.004) * (width - ww);
    float al = random(8, 20);
    fill(20, 80, 160, al);
    rect(xx, yy, ww, random(8, 28), 10);
  }

  // Reflexos de luz brilhando na superfície da água
  for (int i = 0; i < 28; i++) {
    float rx = (i * 91 + frameCount * 0.9) % width;
    float ry = ((i * 57 + oceanScroll * 1.8 + i * 41) % (height + 20));
    fill(170, 215, 255, random(15, 45));
    ellipse(rx, ry, random(4, 14), random(2, 5));
  }

  // Espuma branca representando ondas
  for (int i = 0; i < 18; i++) {
    float wx = (i * 133 + frameCount * 0.6) % width;
    float wy = ((i * 79 + oceanScroll * 3.0 + i * 23) % (height + 20));
    fill(200, 230, 255, random(10, 30));
    ellipse(wx, wy, random(20, 50), random(3, 8));
  }
}

// ============================================================
//  NUVENS (passam de cima para baixo — o avião voa acima delas)
// ============================================================
void drawClouds(boolean moving) {
  for (float[] c : clouds) {
    if (moving) c[1] += c[3]; // Move a nuvem para baixo

    // Reposiciona no topo quando sair pela parte inferior
    if (c[1] > height + 85) {
      c[1] = -85;
      c[0] = random(width);
      c[2] = random(0.7, 1.8);
      c[3] = random(1.2, 2.5);
    }
    drawCloud(c[0], c[1], c[2]);
  }
}

// Desenha uma nuvem individual com camadas sobrepostas para aspecto volumoso
void drawCloud(float x, float y, float sc) {
  noStroke();
  fill(0, 25, 70, 28); // Sombra projetada no oceano abaixo
  ellipse(x + 10, y + 10, 94*sc, 40*sc);
  fill(225, 238, 255, 195); // Corpo principal da nuvem
  ellipse(x, y, 84*sc, 36*sc);
  fill(240, 248, 255, 215); // Nuvens laterais e topo
  ellipse(x - 24*sc, y + 6*sc, 58*sc, 28*sc);
  ellipse(x + 24*sc, y + 6*sc, 58*sc, 28*sc);
  ellipse(x, y - 15*sc, 46*sc, 30*sc);
  fill(255, 255, 255, 120); // Realce branco no topo
  ellipse(x - 6*sc, y - 8*sc, 20*sc, 12*sc);
}

// ============================================================
//  JOGADOR: DESENHO
// ============================================================
void drawPlayer() {
  // Durante hitFlash, o sprite pisca (some em frames alternados)
  if (hitFlash > 0 && hitFlash % 4 < 2) return;

  // Durante invencibilidade, o sprite fica semi-transparente e pulsa
  int alpha = (invincible > 0 && invincible % 6 < 3) ? 110 : 255;
  drawPlayerJet(px, py, 1.0, alpha);
}

// Desenha o jato do jogador usando o PNG carregado
// Usado tanto no jogo quanto no menu (com escala maior)
void drawPlayerJet(float x, float y, float sc, int alpha) {
  pushMatrix();
  translate(x, y);
  scale(sc);
  imageMode(CENTER);
  tint(255, alpha); // Controla a transparência (efeito de invencibilidade)
  image(imgPlayer, 0, 0, 49, 90); // Proporção correta da imagem original
  noTint();
  popMatrix();
}

// ============================================================
//  INIMIGOS E BOSS: DESENHO
// ============================================================
void drawEnemies() {
  for (Enemy e : enemies) e.draw();
}

void drawBoss() {
  if (boss == null) return;
  boss.draw();
}

// ============================================================
//  PROJÉTEIS: DESENHO
// ============================================================

// Projéteis do jogador: retângulos amarelos verticais
void drawBullets() {
  noStroke();
  for (float[] b : bullets) {
    fill(255, 255, 100);          // Núcleo amarelo
    rect(b[0]-2, b[1]-9, 4, 16, 2);
    fill(255, 255, 200, 110);     // Brilho externo mais suave
    rect(b[0]-3, b[1]-12, 6, 22, 3);
  }
}

// Projéteis inimigos: visual diferente para inimigo normal (palito) e boss (circular)
void drawEBullets() {
  noStroke();
  for (float[] b : eBullets) {
    boolean isBoss = (b.length > 4 && b[4] == 1);
    if (isBoss) {
      // Tiro do boss: circular com brilho (estilo original)
      fill(255, 180, 0, 160);
      ellipse(b[0], b[1], 14, 14); // Brilho laranja externo
      fill(255, 60, 60);
      ellipse(b[0], b[1], 8, 8);   // Núcleo vermelho
      fill(255, 240, 200, 200);
      ellipse(b[0], b[1], 4, 4);   // Ponto brilhante central
    } else {
      // Tiro de inimigo normal: retângulo fino vertical
      fill(255, 120, 0, 100);      // Brilho laranja externo
      rect(b[0]-2, b[1]-9, 4, 18, 2);
      fill(255, 50, 30);           // Núcleo vermelho fino
      rect(b[0]-1, b[1]-8, 2, 16, 1);
      fill(255, 230, 180);         // Ponta clara
      ellipse(b[0], b[1]-8, 3, 3);
    }
  }
}

void drawParticles() {
  for (Particle p : particles) p.draw();
}

// ============================================================
//  TEXTOS FLUTUANTES DE PENALIDADE DE SCORE
// ============================================================
void drawScorePenalties() {
  textAlign(CENTER, CENTER);
  for (float[] sp : scorePenalties) {
    // Calcula alpha baseado no tempo de vida restante (desaparece gradualmente)
    float alpha = map(sp[3], 0, 90, 0, 255);
    // Texto vermelho piscante: "-50 pts"
    fill(255, 60, 60, alpha);
    textSize(16);
    text("-" + (int)sp[2] + " pts", sp[0], sp[1]);
  }
}

// ============================================================
//  HUD (Heads-Up Display) — interface sobreposta ao jogo
// ============================================================
void drawHUD() {
  // Barra preta semi-transparente no topo
  fill(0, 0, 0, 175);
  noStroke();
  rect(0, 0, width, 38);

  // Score no canto esquerdo
  fill(255, 220, 0);
  textAlign(LEFT, CENTER);
  textSize(18);
  text("SCORE: " + nf(score, 6), 12, 19);

  // Ícones de vidas (mini-aviões) no centro-esquerdo
  fill(255, 220, 0);
  textSize(13);
  text("VIDAS:", 318, 19);
  for (int i = 0; i < lives; i++) {
    // Desenha um mini-jato para cada vida restante
    pushMatrix();
    translate(390 + i * 28, 19);
    scale(0.38);
    noStroke();
    fill(155, 160, 168);
    beginShape();
    vertex(0,-14); vertex(4,-5); vertex(3,9);
    vertex(0,11); vertex(-3,9); vertex(-4,-5);
    endShape(CLOSE);
    fill(115, 120, 128);
    beginShape();
    vertex(0,-1); vertex(16,8); vertex(10,10);
    vertex(0,3); vertex(-10,10); vertex(-16,8);
    endShape(CLOSE);
    popMatrix();
  }

  // Indicador de wave ou boss no canto direito
  textAlign(RIGHT, CENTER);
  textSize(14);
  if (bossWave) {
    fill(255, 60, 60); // Vermelho para chamar atenção durante o boss
    text("!! BOSS !!", width - 12, 19);
  } else {
    fill(100, 210, 255);
    text("WAVE " + wave, width - 12, 19);
  }

  // Barra de vida do boss (exibida logo abaixo do HUD durante o boss)
  if (bossWave && boss != null) {
    int barW = 400;
    int barH = 18;
    int bx   = width/2 - barW/2;
    int by   = 44;

    // Fundo da barra
    fill(0, 0, 0, 165);
    noStroke();
    rect(bx - 3, by - 3, barW + 6, barH + 6, 5);
    fill(55, 0, 0);
    rect(bx, by, barW, barH, 3);

    // Preenchimento proporcional ao HP restante (verde = cheio, vermelho = quase morto)
    float ratio = (float)boss.hp / boss.maxHp;
    color barCol = lerpColor(color(220, 0, 0), color(0, 210, 70), ratio);
    fill(barCol);
    rect(bx, by, barW * ratio, barH, 3);

    // Texto com HP atual sobre a barra
    fill(255, 220, 0);
    textAlign(CENTER, CENTER);
    textSize(12);
    text("BOSS  " + boss.hp + " / " + boss.maxHp, width/2, by + barH/2);
  }
}

// ============================================================
//  EXPLOSÃO: cria partículas coloridas em uma posição
// ============================================================
void explode(float x, float y, color c) {
  for (int i = 0; i < 22; i++) {
    particles.add(new Particle(x, y, c));
  }
}

// ============================================================
//  BOTÕES DE INTERFACE
// ============================================================

// Desenha um botão retangular com efeito hover (quando o mouse está sobre ele)
void drawButton(String label, float x, float y, boolean hover) {
  int w = 264, h = 46;
  strokeWeight(2);
  if (hover) {
    fill(255, 220, 0);     // Amarelo quando hover
    stroke(255, 220, 0);
  } else {
    fill(10, 30, 80, 220); // Azul escuro no estado normal
    stroke(80, 130, 240);
  }
  rect(x - w/2, y - h/2, w, h, 8);
  noStroke();
  fill(hover ? color(10, 10, 10) : color(170, 205, 255));
  textAlign(CENTER, CENTER);
  textSize(18);
  text(label, x, y);
}

// Verifica se o mouse está sobre a área de um botão
boolean isMouseOnBtn(float x, float y) {
  int w = 264, h = 46;
  return (mouseX > x-w/2 && mouseX < x+w/2 && mouseY > y-h/2 && mouseY < y+h/2);
}

// ============================================================
//  EVENTOS DE MOUSE E TECLADO
// ============================================================
void mousePressed() {
  switch (gameState) {
    case STATE_MENU:
      if (isMouseOnBtn(width/2, 420)) { initGame(); musicaJogo.loop(); gameState = STATE_PLAYING; }
      if (isMouseOnBtn(width/2, 485)) { gameState = STATE_SCORES; }
      break;
    case STATE_SCORES:
      if (isMouseOnBtn(width/2, 510)) { gameState = STATE_MENU; }
      break;
    case STATE_PAUSED:
      if (isMouseOnBtn(width/2, 330)) { gameState = STATE_PLAYING; }  // Retoma o jogo
      if (isMouseOnBtn(width/2, 400)) { musicaJogo.stop(); gameState = STATE_MENU; } // Sai da partida
      break;
    case STATE_GAMEOVER:
      if (isMouseOnBtn(width/2, 368)) { nameBuffer = ""; gameState = STATE_NAME_ENTRY; }
      if (isMouseOnBtn(width/2, 428)) { initGame(); musicaJogo.loop(); gameState = STATE_PLAYING; }
      if (isMouseOnBtn(width/2, 488)) { gameState = STATE_MENU; }
      break;
  }
}

void keyPressed() {
  // Registra a tecla pressionada no array de teclas
  if (keyCode < keys.length) keys[keyCode] = true;
  if (key == ' ') keys[32] = true;

  // Pausa com a tecla P durante o jogo
  if (gameState == STATE_PLAYING && (key == 'p' || key == 'P')) {
    gameState = STATE_PAUSED;
  }

  // Captura o nome digitado na tela de entrada de nome
  if (gameState == STATE_NAME_ENTRY) {
    if (key == BACKSPACE && nameBuffer.length() > 0) {
      nameBuffer = nameBuffer.substring(0, nameBuffer.length()-1);
    } else if (key == ENTER || key == RETURN) {
      saveScore();          // Salva no ranking
      gameState = STATE_SCORES; // Vai para a tela de scores
    } else if (nameBuffer.length() < 8 && key != BACKSPACE && key >= 32 && key < 127) {
      nameBuffer += Character.toUpperCase(key); // Adiciona letra em maiúsculo
    }
  }
}

void keyReleased() {
  // Remove a tecla do array quando solta
  if (keyCode < keys.length) keys[keyCode] = false;
  if (key == ' ') keys[32] = false;
}

// ============================================================
//  SALVAR SCORE NO RANKING
// ============================================================
void saveScore() {
  // Usa "ACE" se o nome estiver em branco
  String name = (nameBuffer.trim().length() == 0) ? "ACE" : nameBuffer.trim();

  // Insere no ranking na posição correta (ordem decrescente de pontuação)
  for (int i = 0; i < 5; i++) {
    if (score > topScores[i]) {
      // Desloca os registros abaixo para abrir espaço
      for (int j = 4; j > i; j--) {
        topScores[j] = topScores[j-1];
        topNames[j]  = topNames[j-1];
      }
      topScores[i] = score;
      topNames[i]  = name;
      break;
    }
  }
  nameBuffer = "";
}

// ============================================================
//  CLASSE ENEMY — inimigo individual
// ============================================================
class Enemy {
  float x, y;        // Posição atual
  float vx;          // Velocidade lateral atual
  float targetVx;    // Velocidade lateral alvo (muda periodicamente)
  int   driftTimer;  // Contador para trocar a direção lateral
  int   type;        // Tipo visual (0=soviético, 1=nazista, 2=MiG)
  color col;         // Cor das partículas de explosão deste inimigo

  Enemy() {
    x         = random(40, width - 40); // Aparece em X aleatório no topo
    y         = -52;                    // Começa fora da tela (acima)
    vx        = 0;
    targetVx  = random(-1.4, 1.4);      // Direção lateral inicial aleatória
    driftTimer = (int)random(40, 100);  // Tempo até primeira troca de direção
    type = (int)random(3);              // Tipo aleatório entre os 3 disponíveis
    // Cor de explosão diferente por tipo (para variedade visual)
    switch (type) {
      case 0: col = color(200, 30, 30); break; // Soviético: vermelho
      case 1: col = color(45,  45, 50); break; // Nazista: cinza escuro
      case 2: col = color(165, 125, 0); break; // MiG: dourado
    }
  }

  void update(float spd) {
    // Decrementa o timer; quando zerar, escolhe uma nova direção aleatória
    driftTimer--;
    if (driftTimer <= 0) {
      driftTimer = (int)random(50, 120);
      targetVx   = random(-1.6, 1.6);
    }

    // Suaviza a transição para a velocidade alvo (estilo Galaga)
    vx = lerp(vx, targetVx, 0.04);

    // Inverte a direção ao se aproximar das bordas da tela
    if (x < 35)         targetVx =  abs(targetVx) + 0.3;
    if (x > width - 35) targetVx = -abs(targetVx) - 0.3;

    x += vx;  // Aplica movimento lateral
    y += spd; // Desce em direção ao jogador
  }

  void draw() {
    // Renderiza o PNG do inimigo centralizado na posição atual
    // Nariz do PNG aponta para baixo (em direção ao jogador)
    pushMatrix();
    translate(x, y);
    imageMode(CENTER);
    image(imgEnemy, 0, 0, 90, 49); // Proporção correta: 1408x768 -> 90x49
    popMatrix();
  }
}

// ============================================================
//  CLASSE BOSS — inimigo especial das waves múltiplas de 5
// ============================================================
class Boss {
  float x, y;       // Posição atual
  int   hp, maxHp;  // HP atual e máximo
  float radius = 58; // Raio de colisão (usado para detectar acertos de bala)
  float targetX;    // Posição X alvo para oscilação lateral

  Boss(int hp) {
    this.hp    = hp;
    this.maxHp = hp;
    x       = width / 2; // Entra pelo centro da tela
    y       = -90;       // Começa fora da tela (acima)
    targetX = random(140, width - 140);
  }

  void update() {
    float targetY = 140; // Posição Y onde o boss para (terço superior da tela)
    if (y < targetY) y += 1.6; // Desce até atingir a posição alvo

    // Oscilação lateral suave: interpola em direção ao targetX
    x = lerp(x, targetX, 0.012);
    if (abs(x - targetX) < 12) targetX = random(140, width - 140); // Novo alvo
    x = constrain(x, 90, width - 90); // Mantém dentro da tela
  }

  void draw() {
    pushMatrix();
    translate(x, y);
    imageMode(CENTER);
    // Pisca em vermelho quando com menos de 30% de HP
    float ratio = (float)hp / maxHp;
    if (ratio < 0.3 && frameCount % 10 < 5) {
      tint(255, 80, 80); // Tint vermelho para indicar estado crítico
    }
    image(imgBoss, 0, 0, 200, 109); // Proporção correta: 1408x768 -> 200x109
    noTint();
    popMatrix();
  }
}

// ============================================================
//  CLASSE PARTICLE — partícula individual de explosão
// ============================================================
class Particle {
  float x, y;        // Posição atual
  float vx, vy;      // Velocidade (direção e intensidade aleatórias)
  float life;        // Tempo de vida restante (em frames)
  float maxLife;     // Tempo de vida total (para calcular alpha)
  float sz;          // Tamanho da partícula
  color c;           // Cor base da partícula

  Particle(float x, float y, color c) {
    this.x = x; this.y = y; this.c = c;
    // Velocidade aleatória em todas as direções
    float ang = random(TWO_PI);
    float spd = random(1, 5.5);
    vx = cos(ang)*spd;
    vy = sin(ang)*spd;
    maxLife = life = random(22, 50); // Tempo de vida aleatório
    sz = random(3, 9);               // Tamanho aleatório
  }

  void update() {
    x += vx; y += vy;  // Move pela velocidade
    vx *= 0.95;        // Desacelera gradualmente (resistência do ar)
    vy *= 0.95;
    life--;            // Envelhece um frame
  }

  // Retorna true quando a partícula expirou e deve ser removida
  boolean isDead() { return life <= 0; }

  void draw() {
    // Calcula alpha decrescente: começa opaca e some gradualmente
    float alpha = map(life, 0, maxLife, 0, 255);
    noStroke();
    fill(red(c), green(c), blue(c), alpha);
    ellipse(x, y, sz, sz);
    // Brilho central mais claro
    fill(255, 255, 200, alpha * 0.38);
    ellipse(x, y, sz * 0.4, sz * 0.4);
  }
}
