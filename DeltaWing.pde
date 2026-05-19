import processing.sound.*;

// ============================================================
//  DELTA WING - Jogo de Ação 2D estilo retrô
//  Desenvolvido em Processing (Java)
//  Vista de cima - oceano embaixo, nuvens acima
// ============================================================

// ---------- ESTADOS DO JOGO ----------
final int STATE_MENU       = 0;
final int STATE_SCORES     = 1;
final int STATE_PLAYING    = 2;
final int STATE_PAUSED     = 3;
final int STATE_GAMEOVER   = 4;
final int STATE_NAME_ENTRY = 5;

int gameState = STATE_MENU;

// ---------- PONTUAÇÃO / VIDAS ----------
int   score         = 0;
int   lives         = 3;
int   wave          = 1;
float waveTimer     = 0;
float spawnInterval = 3.0;
int   maxEnemies    = 3;

// ---------- TOP 5 ----------
String[] topNames  = new String[5];
int[]    topScores = new int[5];
String   nameBuffer = "";

// ---------- JOGADOR ----------
float px, py;
float pSpeed    = 4.5;
boolean[] keys  = new boolean[526];
int shootCooldown = 0;
int hitFlash      = 0;
int invincible    = 0;

// ---------- PROJÉTEIS JOGADOR ----------
ArrayList<float[]> bullets  = new ArrayList<float[]>();

// ---------- INIMIGOS NORMAIS ----------
ArrayList<Enemy> enemies = new ArrayList<Enemy>();
float spawnAccum = 0;

// ---------- BOSS ----------
Boss boss         = null;
boolean bossWave  = false;
boolean bossDefeated = false;

// ---------- PROJÉTEIS INIMIGOS ----------
ArrayList<float[]> eBullets = new ArrayList<float[]>();

// ---------- PARTÍCULAS ----------
ArrayList<Particle> particles = new ArrayList<Particle>();

// ---------- OCEANO ----------
float oceanScroll = 0;

// ---------- NUVENS ----------
float[][] clouds = new float[10][4]; // x, y, escala, velocidade

// ============================================================
// ---------- SPRITES PNG ----------
PImage imgPlayer;
PImage imgEnemy;
PImage imgBoss;

// ---------- SONS ----------
SoundFile somTiroPlayer;
SoundFile somTiroInimigo;
SoundFile somMorteInimigo;
SoundFile somDanoPlayer;
SoundFile somMortePlayer;
SoundFile somMorteBoss;

void setup() {
  size(800, 600);
  textFont(createFont("Courier New Bold", 16, true));

  // Carrega os sprites da pasta data/
  imgPlayer = loadImage("Player.png");
  imgEnemy  = loadImage("Inimigo.png");
  imgBoss   = loadImage("Boss.png");

  // Carrega os sons da pasta data/
  somTiroPlayer   = new SoundFile(this, "TiroPlayer.wav");
  somTiroInimigo  = new SoundFile(this, "TiroInimigo.wav");
  somMorteInimigo = new SoundFile(this, "MorteInimigo.wav");
  somDanoPlayer   = new SoundFile(this, "DanoNoPlayer.wav");
  somMortePlayer  = new SoundFile(this, "MortePlayer.wav");
  somMorteBoss    = new SoundFile(this, "MorteBoss.wav");

  initScores();
  initClouds();
  initGame();
}

// ============================================================
void initGame() {
  px = width / 2;
  py = height - 110;
  lives = 3;
  score = 0;
  wave  = 1;
  waveTimer = 0;
  spawnInterval = 3.0;
  maxEnemies    = 3;
  spawnAccum    = 0;
  bossWave      = false;
  bossDefeated  = false;
  boss          = null;
  enemies.clear();
  bullets.clear();
  eBullets.clear();
  particles.clear();
  shootCooldown = 0;
  invincible    = 0;
  hitFlash      = 0;
}

void initClouds() {
  for (int i = 0; i < clouds.length; i++) {
    clouds[i][0] = random(width);
    clouds[i][1] = random(-40, height);
    clouds[i][2] = random(0.7, 1.8);
    clouds[i][3] = random(1.2, 2.5);
  }
}

void initScores() {
  for (int i = 0; i < 5; i++) {
    topNames[i]  = "---";
    topScores[i] = 0;
  }
}

// ============================================================
void draw() {
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
//  MENU PRINCIPAL
// ============================================================
void drawMenu() {
  drawOceanBackground(false);
  drawClouds(false);

  fill(0, 0, 0, 150);
  noStroke();
  rect(width/2 - 310, 88, 620, 118, 12);

  fill(255, 220, 0);
  textAlign(CENTER, CENTER);
  textSize(62);
  text("DELTA WING", width/2, 138);

  fill(180, 220, 255);
  textSize(15);
  text("AIR SUPERIORITY COMBAT  |  TOP-DOWN SHOOTER", width/2, 186);

  drawPlayerJet(width/2, 310, 2.6, 255);

  drawButton("[ JOGAR ]",           width/2, 420, isMouseOnBtn(width/2, 420));
  drawButton("[ MELHORES SCORES ]", width/2, 485, isMouseOnBtn(width/2, 485));

  fill(70, 100, 160);
  textSize(11);
  text("SETAS = mover  |  ESPACO = atirar  |  P = pausar", width/2, 575);
}

// ============================================================
//  TELA DE SCORES
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

  textSize(20);
  for (int i = 0; i < 5; i++) {
    color c;
    if      (i == 0) c = color(255, 215, 0);
    else if (i == 1) c = color(192, 192, 192);
    else if (i == 2) c = color(205, 127, 50);
    else              c = color(160, 190, 255);
    fill(c);
    text((i+1) + ".  " + topNames[i] + "   " + nf(topScores[i], 6), width/2, 194 + i * 58);
  }

  drawButton("[ VOLTAR ]", width/2, 510, isMouseOnBtn(width/2, 510));
}

// ============================================================
//  JOGO EM ANDAMENTO
// ============================================================
void drawPlaying() {
  drawOceanBackground(true);
  drawClouds(true);

  updateWave();
  updatePlayer();
  updateBullets();
  if (bossWave && boss != null) updateBoss();
  else                          updateEnemies();
  updateEBullets();
  updateParticles();

  drawParticles();
  drawEBullets();
  if (bossWave && boss != null) drawBoss();
  else                          drawEnemies();
  drawBullets();
  drawPlayer();
  drawHUD();
}

// ============================================================
//  PAUSA
// ============================================================
void drawPaused() {
  drawOceanBackground(false);
  drawClouds(false);
  drawParticles();
  drawEBullets();
  if (bossWave && boss != null) drawBoss();
  else drawEnemies();
  drawBullets();
  drawPlayer();
  drawHUD();

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
//  GAME OVER
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
//  ENTRADA DE NOME
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

  stroke(255, 220, 0);
  strokeWeight(2);
  noFill();
  rect(width/2 - 120, 304, 240, 48, 6);
  noStroke();

  fill(255, 220, 0);
  textSize(26);
  text(nameBuffer + (frameCount % 30 < 15 ? "|" : ""), width/2, 330);

  fill(140, 165, 215);
  textSize(13);
  text("ENTER = confirmar  |  BACKSPACE = apagar", width/2, 398);
}

// ============================================================
//  UPDATE — WAVE
// ============================================================
void updateWave() {
  // Durante wave de boss, o timer NÃO avança — só sai quando boss for morto
  if (!bossWave) {
    waveTimer += 1.0 / frameRate;
  }

  // Wave normal: avança por tempo
  boolean timeUp = (!bossWave && waveTimer > 20.0);

  // Boss: avança APENAS quando bossDefeated for true (boss morto em updateBullets)
  boolean bossCleared = (bossWave && bossDefeated);

  if (timeUp || bossCleared) {
    waveTimer    = 0;
    spawnAccum   = 0;
    bossDefeated = false;

    if (!bossWave) wave++;

    if (wave % 5 == 0 && !bossWave) {
      bossWave = true;
      enemies.clear();
      eBullets.clear();
      int bossHp = 40 + (wave / 5) * 20;
      boss = new Boss(bossHp);
    } else {
      bossWave = false;
      boss     = null;
      spawnInterval = max(0.8, 3.0 - wave * 0.15);
      maxEnemies    = min(10, 3 + wave);
    }
  }
}

// ---------- JOGADOR ----------
void updatePlayer() {
  if (keys[LEFT]  && px > 30)           px -= pSpeed;
  if (keys[RIGHT] && px < width - 30)   px += pSpeed;
  if (keys[UP]    && py > 40)           py -= pSpeed;
  if (keys[DOWN]  && py < height - 30)  py += pSpeed;

  if (shootCooldown > 0) shootCooldown--;
  if (keys[32] && shootCooldown == 0) {
    bullets.add(new float[]{px - 11, py - 18});
    bullets.add(new float[]{px + 11, py - 18});
    shootCooldown = 12;
    somTiroPlayer.stop();
    somTiroPlayer.play();
  }

  if (invincible > 0) invincible--;
  if (hitFlash  > 0) hitFlash--;
}

// ---------- PROJÉTEIS DO JOGADOR ----------
void updateBullets() {
  for (int i = bullets.size() - 1; i >= 0; i--) {
    float[] b = bullets.get(i);
    b[1] -= 10;
    if (b[1] < -10) { bullets.remove(i); continue; }

    boolean hit = false;
    for (int j = enemies.size() - 1; j >= 0; j--) {
      Enemy e = enemies.get(j);
      if (dist(b[0], b[1], e.x, e.y) < 22) {
        explode(e.x, e.y, e.col);
        enemies.remove(j);
        bullets.remove(i);
        score += 100 + wave * 10;
        somMorteInimigo.stop();
        somMorteInimigo.play();
        hit = true;
        break;
      }
    }
    if (hit) continue;

    if (bossWave && boss != null) {
      if (dist(b[0], b[1], boss.x, boss.y) < boss.radius) {
        boss.hp--;
        explode(b[0], b[1], color(255, 200, 0));
        bullets.remove(i);
        if (boss.hp <= 0) {
          explode(boss.x,      boss.y,      color(255, 100, 0));
          explode(boss.x - 25, boss.y + 15, color(255,  60, 0));
          explode(boss.x + 25, boss.y - 15, color(200, 200, 0));
          score += 1000 + wave * 50;
          somMorteBoss.stop();
          somMorteBoss.play();
          boss         = null;
          bossDefeated = true;
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

// ---------- INIMIGOS NORMAIS ----------
void updateEnemies() {
  spawnAccum += 1.0 / frameRate;
  if (spawnAccum >= spawnInterval && enemies.size() < maxEnemies) {
    spawnAccum = 0;
    enemies.add(new Enemy());
  }

  float baseSpeed = 1.5 + wave * 0.12;

  for (int i = enemies.size() - 1; i >= 0; i--) {
    Enemy e = enemies.get(i);
    e.update(baseSpeed);

    if (random(1) < 0.018 + wave * 0.002) {
      // Tiro reto para baixo, sem deriva lateral
      float spd = 4.0 + wave * 0.08;
      eBullets.add(new float[]{e.x, e.y, 0, spd});
      somTiroInimigo.stop();
      somTiroInimigo.play();
    }

    // Colisao corpo-a-corpo: inimigo toca o jogador
    if (invincible == 0 && dist(e.x, e.y, px, py) < 26) {
      explode(e.x, e.y, e.col);
      enemies.remove(i);
      lives--;
      hitFlash   = 22;
      invincible = 90;
      explode(px, py, color(255, 100, 0));
      somMorteInimigo.stop();
      somMorteInimigo.play();
      if (lives <= 0) {
        somMortePlayer.stop();
        somMortePlayer.play();
        gameState = STATE_GAMEOVER;
      } else {
        somDanoPlayer.stop();
        somDanoPlayer.play();
      }
      continue;
    }

    if (e.y > height + 50) enemies.remove(i);
  }
}

// ---------- BOSS ----------
void updateBoss() {
  if (boss == null) return;
  boss.update();

  // Colisao corpo-a-corpo: jogador toca o boss
  if (invincible == 0 && dist(px, py, boss.x, boss.y) < boss.radius + 18) {
    lives--;
    hitFlash   = 22;
    invincible = 90;
    explode(px, py, color(255, 100, 0));
    if (lives <= 0) {
      somMortePlayer.stop();
      somMortePlayer.play();
      gameState = STATE_GAMEOVER;
    } else {
      somDanoPlayer.stop();
      somDanoPlayer.play();
    }
  }

  // tiros do boss em leque
  if (random(1) < 0.022 + wave * 0.002) {
    for (int k = -1; k <= 1; k++) {
      float ang = atan2(py - boss.y, px - boss.x) + k * 0.22;
      float spd = 3.0;
      eBullets.add(new float[]{boss.x, boss.y + boss.radius * 0.5,
                                cos(ang)*spd, sin(ang)*spd});
    }
  }
}

// ---------- PROJÉTEIS INIMIGOS ----------
void updateEBullets() {
  for (int i = eBullets.size() - 1; i >= 0; i--) {
    float[] b = eBullets.get(i);
    b[0] += b[2];
    b[1] += b[3];

    if (b[0] < -10 || b[0] > width+10 || b[1] < -10 || b[1] > height+10) {
      eBullets.remove(i); continue;
    }

    if (invincible == 0 && dist(b[0], b[1], px, py) < 18) {
      eBullets.remove(i);
      lives--;
      hitFlash   = 22;
      invincible = 90;
      explode(px, py, color(255, 100, 0));
      if (lives <= 0) {
        somMortePlayer.stop();
        somMortePlayer.play();
        gameState = STATE_GAMEOVER;
      } else {
        somDanoPlayer.stop();
        somDanoPlayer.play();
      }
    }
  }
}

void updateParticles() {
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    if (p.isDead()) particles.remove(i);
  }
}

// ============================================================
//  FUNDO — OCEANO VISTA DE CIMA
// ============================================================
void drawOceanBackground(boolean moving) {
  // Cor base do oceano
  background(8, 55, 110);

  if (moving) oceanScroll += 2.0;
  if (oceanScroll > 60) oceanScroll -= 60;

  noStroke();

  // Faixas de corrente oceânica (rolam para baixo)
  for (int i = 0; i < 12; i++) {
    float yy  = ((i * 55 + oceanScroll * 2.5) % (height + 60)) - 30;
    float ww  = random(width * 0.25, width * 0.65);
    float xx  = noise(i * 3.7, frameCount * 0.004) * (width - ww);
    float al  = random(8, 20);
    fill(20, 80, 160, al);
    rect(xx, yy, ww, random(8, 28), 10);
  }

  // Brilhos/reflexos na água
  for (int i = 0; i < 28; i++) {
    float rx = (i * 91 + frameCount * 0.9) % width;
    float ry = ((i * 57 + oceanScroll * 1.8 + i * 41) % (height + 20));
    fill(170, 215, 255, random(15, 45));
    ellipse(rx, ry, random(4, 14), random(2, 5));
  }

  // Espuma / ondas brancas (linhas curtas)
  for (int i = 0; i < 18; i++) {
    float wx = (i * 133 + frameCount * 0.6) % width;
    float wy = ((i * 79  + oceanScroll * 3.0 + i * 23) % (height + 20));
    fill(200, 230, 255, random(10, 30));
    ellipse(wx, wy, random(20, 50), random(3, 8));
  }
}

// ============================================================
//  NUVENS (passando de cima para baixo — abaixo do avião)
// ============================================================
void drawClouds(boolean moving) {
  for (float[] c : clouds) {
    if (moving) {
      c[1] += c[3];
    }
    if (c[1] > height + 85) {
      c[1] = -85;
      c[0] = random(width);
      c[2] = random(0.7, 1.8);
      c[3] = random(1.2, 2.5);
    }
    drawCloud(c[0], c[1], c[2]);
  }
}

void drawCloud(float x, float y, float sc) {
  noStroke();
  // sombra no oceano
  fill(0, 25, 70, 28);
  ellipse(x + 10, y + 10, 94*sc, 40*sc);
  // corpo da nuvem
  fill(225, 238, 255, 195);
  ellipse(x, y, 84*sc, 36*sc);
  fill(240, 248, 255, 215);
  ellipse(x - 24*sc, y + 6*sc, 58*sc, 28*sc);
  ellipse(x + 24*sc, y + 6*sc, 58*sc, 28*sc);
  ellipse(x, y - 15*sc, 46*sc, 30*sc);
  // realce branco
  fill(255, 255, 255, 120);
  ellipse(x - 6*sc, y - 8*sc, 20*sc, 12*sc);
}

// ============================================================
//  JOGADOR (vista de cima, nariz aponta para cima)
// ============================================================
void drawPlayer() {
  if (hitFlash > 0 && hitFlash % 4 < 2) return;
  int alpha = (invincible > 0 && invincible % 6 < 3) ? 110 : 255;
  drawPlayerJet(px, py, 1.0, alpha);
}

void drawPlayerJet(float x, float y, float sc, int alpha) {
  pushMatrix();
  translate(x, y);
  scale(sc);
  imageMode(CENTER);
  // Aplica alpha para o efeito de piscar ao tomar dano
  tint(255, alpha);
  image(imgPlayer, 0, 0, 49, 90);
  noTint();
  popMatrix();
}

// ============================================================
//  INIMIGOS
// ============================================================
void drawEnemies() {
  for (Enemy e : enemies) e.draw();
}

void drawBoss() {
  if (boss == null) return;
  boss.draw();
}

// ============================================================
//  PROJÉTEIS
// ============================================================
void drawBullets() {
  noStroke();
  for (float[] b : bullets) {
    fill(255, 255, 100);
    rect(b[0]-2, b[1]-9, 4, 16, 2);
    fill(255, 255, 200, 110);
    rect(b[0]-3, b[1]-12, 6, 22, 3);
  }
}

void drawEBullets() {
  noStroke();
  for (float[] b : eBullets) {
    // Projétil fino vertical (sempre reto para baixo)
    // Brilho externo
    fill(255, 120, 0, 100);
    rect(b[0]-2, b[1]-9, 4, 18, 2);
    // Núcleo vermelho fino
    fill(255, 50, 30);
    rect(b[0]-1, b[1]-8, 2, 16, 1);
    // Ponta clara
    fill(255, 230, 180);
    ellipse(b[0], b[1]-8, 3, 3);
  }
}

void drawParticles() {
  for (Particle p : particles) p.draw();
}

// ============================================================
//  HUD
// ============================================================
void drawHUD() {
  fill(0, 0, 0, 175);
  noStroke();
  rect(0, 0, width, 38);

  fill(255, 220, 0);
  textAlign(LEFT, CENTER);
  textSize(18);
  text("SCORE: " + nf(score, 6), 12, 19);

  fill(255, 220, 0);
  textSize(13);
  text("VIDAS:", 318, 19);
  for (int i = 0; i < lives; i++) {
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

  if (bossWave) {
    fill(255, 60, 60);
  } else {
    fill(100, 210, 255);
  }
  textAlign(RIGHT, CENTER);
  textSize(14);
  text(bossWave ? "!! BOSS !!" : "WAVE " + wave, width - 12, 19);

  // Barra de vida do boss
  if (bossWave && boss != null) {
    int barW = 400;
    int barH = 18;
    int bx   = width/2 - barW/2;
    int by   = 44;

    fill(0, 0, 0, 165);
    noStroke();
    rect(bx - 3, by - 3, barW + 6, barH + 6, 5);

    fill(55, 0, 0);
    rect(bx, by, barW, barH, 3);

    float ratio = (float)boss.hp / boss.maxHp;
    color barCol = lerpColor(color(220, 0, 0), color(0, 210, 70), ratio);
    fill(barCol);
    rect(bx, by, barW * ratio, barH, 3);

    fill(255, 220, 0);
    textAlign(CENTER, CENTER);
    textSize(12);
    text("BOSS  " + boss.hp + " / " + boss.maxHp, width/2, by + barH/2);
  }
}

// ============================================================
//  EXPLOSÃO
// ============================================================
void explode(float x, float y, color c) {
  for (int i = 0; i < 22; i++) {
    particles.add(new Particle(x, y, c));
  }
}

// ============================================================
//  BOTÕES
// ============================================================
void drawButton(String label, float x, float y, boolean hover) {
  int w = 264, h = 46;
  strokeWeight(2);
  if (hover) {
    fill(255, 220, 0);
    stroke(255, 220, 0);
  } else {
    fill(10, 30, 80, 220);
    stroke(80, 130, 240);
  }
  rect(x - w/2, y - h/2, w, h, 8);
  noStroke();
  fill(hover ? color(10, 10, 10) : color(170, 205, 255));
  textAlign(CENTER, CENTER);
  textSize(18);
  text(label, x, y);
}

boolean isMouseOnBtn(float x, float y) {
  int w = 264, h = 46;
  return (mouseX > x-w/2 && mouseX < x+w/2 && mouseY > y-h/2 && mouseY < y+h/2);
}

// ============================================================
//  EVENTOS
// ============================================================
void mousePressed() {
  switch (gameState) {
    case STATE_MENU:
      if (isMouseOnBtn(width/2, 420)) { initGame(); gameState = STATE_PLAYING; }
      if (isMouseOnBtn(width/2, 485)) { gameState = STATE_SCORES; }
      break;
    case STATE_SCORES:
      if (isMouseOnBtn(width/2, 510)) { gameState = STATE_MENU; }
      break;
    case STATE_PAUSED:
      if (isMouseOnBtn(width/2, 330)) { gameState = STATE_PLAYING; }
      if (isMouseOnBtn(width/2, 400)) { gameState = STATE_MENU; }
      break;
    case STATE_GAMEOVER:
      if (isMouseOnBtn(width/2, 368)) { nameBuffer = ""; gameState = STATE_NAME_ENTRY; }
      if (isMouseOnBtn(width/2, 428)) { initGame(); gameState = STATE_PLAYING; }
      if (isMouseOnBtn(width/2, 488)) { gameState = STATE_MENU; }
      break;
  }
}

void keyPressed() {
  if (keyCode < keys.length) keys[keyCode] = true;
  if (key == ' ') keys[32] = true;

  if (gameState == STATE_PLAYING && (key == 'p' || key == 'P')) {
    gameState = STATE_PAUSED;
  }

  if (gameState == STATE_NAME_ENTRY) {
    if (key == BACKSPACE && nameBuffer.length() > 0) {
      nameBuffer = nameBuffer.substring(0, nameBuffer.length()-1);
    } else if (key == ENTER || key == RETURN) {
      saveScore();
      gameState = STATE_SCORES;
    } else if (nameBuffer.length() < 8 && key != BACKSPACE && key >= 32 && key < 127) {
      nameBuffer += Character.toUpperCase(key);
    }
  }
}

void keyReleased() {
  if (keyCode < keys.length) keys[keyCode] = false;
  if (key == ' ') keys[32] = false;
}

// ============================================================
//  SCORE
// ============================================================
void saveScore() {
  String name = (nameBuffer.trim().length() == 0) ? "ACE" : nameBuffer.trim();
  for (int i = 0; i < 5; i++) {
    if (score > topScores[i]) {
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
//  CLASSE ENEMY — movimento lateral estilo Galaga
// ============================================================
class Enemy {
  float x, y;
  float vx;
  float targetVx;
  int   driftTimer;
  int   type;
  color col;

  Enemy() {
    x         = random(40, width - 40);
    y         = -52;
    vx        = 0;
    targetVx  = random(-1.4, 1.4);
    driftTimer = (int)random(40, 100);
    type = (int)random(3);
    switch (type) {
      case 0: col = color(200, 30, 30); break; // soviético
      case 1: col = color(45,  45, 50); break; // nazista
      case 2: col = color(165, 125, 0); break; // MiG
    }
  }

  void update(float spd) {
    // Troca suavemente de direção lateral periodicamente
    driftTimer--;
    if (driftTimer <= 0) {
      driftTimer = (int)random(50, 120);
      targetVx   = random(-1.6, 1.6);
    }
    // Interpola vx em direção ao alvo — movimento suave
    vx = lerp(vx, targetVx, 0.04);

    // Mantém dentro dos limites invertendo o alvo
    if (x < 35)         targetVx =  abs(targetVx) + 0.3;
    if (x > width - 35) targetVx = -abs(targetVx) - 0.3;

    x += vx;
    y += spd;
  }

  void draw() {
    // Usa o PNG do inimigo — nariz aponta para baixo (em direcao ao jogador)
    pushMatrix();
    translate(x, y);
    imageMode(CENTER);
    image(imgEnemy, 0, 0, 90, 49);
    popMatrix();
  }

}

// ============================================================
//  CLASSE BOSS — grande bombardeiro soviético, desce e fica fixo
// ============================================================
class Boss {
  float x, y;
  int   hp, maxHp;
  float radius = 58;
  float targetX;

  Boss(int hp) {
    this.hp    = hp;
    this.maxHp = hp;
    x       = width / 2;
    y       = -90;
    targetX = random(140, width - 140);
  }

  void update() {
    float targetY = 140;
    if (y < targetY) y += 1.6;

    // oscila suavemente para os lados
    x = lerp(x, targetX, 0.012);
    if (abs(x - targetX) < 12) targetX = random(140, width - 140);
    x = constrain(x, 90, width - 90);
  }

  void draw() {
    // Usa o PNG do boss — nariz aponta para baixo
    pushMatrix();
    translate(x, y);
    imageMode(CENTER);
    // Pisca em vermelho quando com pouca vida (menos de 30%)
    float ratio = (float)hp / maxHp;
    if (ratio < 0.3 && frameCount % 10 < 5) {
      tint(255, 80, 80);
    }
    image(imgBoss, 0, 0, 200, 109);
    noTint();
    popMatrix();
  }


}

// ============================================================
//  PARTÍCULA
// ============================================================
class Particle {
  float x, y, vx, vy, life, maxLife, sz;
  color c;

  Particle(float x, float y, color c) {
    this.x = x; this.y = y; this.c = c;
    float ang = random(TWO_PI);
    float spd = random(1, 5.5);
    vx = cos(ang)*spd;
    vy = sin(ang)*spd;
    maxLife = life = random(22, 50);
    sz = random(3, 9);
  }

  void update() {
    x += vx; y += vy;
    vx *= 0.95; vy *= 0.95;
    life--;
  }

  boolean isDead() { return life <= 0; }

  void draw() {
    float alpha = map(life, 0, maxLife, 0, 255);
    noStroke();
    fill(red(c), green(c), blue(c), alpha);
    ellipse(x, y, sz, sz);
    fill(255, 255, 200, alpha * 0.38);
    ellipse(x, y, sz * 0.4, sz * 0.4);
  }
}
