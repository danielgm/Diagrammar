
class EmojiWorld {
  int worldWidth;
  int worldHeight;
  int gridSize;
  int numRows;
  int numCols;

  int minParticles;
  ArrayList<EmojiParticle> particles;
  int currGroupIndex;
  EmojiPlayer player;

  EmojiWorld(int w, int h) {
    worldWidth = w;
    worldHeight = h;
    
    gridSize = 20;
    numCols = ceil(worldWidth / 20);
    numRows = ceil(worldHeight / 20);

    minParticles = 80;

    reset();
  }

  void reset() {
    particles = new ArrayList<EmojiParticle>();

    player = new EmojiPlayer(this, 0, new PVector(worldWidth/2, worldHeight/2));
    particles.add(player);

    for (int i = 1; i < minParticles; ++i) {
      particles.add(place(new EmojiParticle(this, i)));
    }
    currGroupIndex = 0;
  }
  
  void step() {
    Iterator<EmojiParticle> iter;

    // FIXME: Implement using iterator?
    for (int i = 1; i < particles.size (); i++) {
      EmojiParticle p = particles.get(i);
      if (!p.visible()) {
        particles.set(i, place(new EmojiParticle(this, i)));
        i--;
      }
    }

    iter = particles.iterator();
    while (iter.hasNext()) {
      EmojiParticle p = iter.next();
      p.step();
    }

    for (int i = 0; i < particles.size () - 1; i++) {
      EmojiParticle p = particles.get(i);
      for (int j = i + 1; j < particles.size (); j++) {
        EmojiParticle q = particles.get(j);
        if (p.collision(q)) {
          handleCollision(p, q);
        }
      }
    }
  }

  void draw(PGraphics g) {
    g.background(0);
    drawGrid(g);

    g.fill(255);
    Iterator<EmojiParticle> iter = particles.iterator();
    while (iter.hasNext()) {
      EmojiParticle p = iter.next();
      p.draw(g);
    }
  }
  
  void drawGrid(PGraphics g) {
    g.stroke(32);
    g.noFill();
    for (int c = 0; c <= numCols; c++) {
      g.line(c * gridSize, 0, c * gridSize, worldHeight);
    }
    for (int r = 0; r <= numRows; r++) {
      g.line(0, r * gridSize, worldWidth, r * gridSize);
    }
  }

  EmojiParticle place(EmojiParticle p) {
    while (dist (player.pos.x, player.pos.y, p.pos.x, p.pos.y) < 250 || collision(p)) {
      p.pos.x = random(width);
      p.pos.y = random(height);
    }
    return p;
  }

  boolean collision(EmojiParticle p) {
    Iterator<EmojiParticle> iter = particles.iterator();
    while (iter.hasNext ()) {
      EmojiParticle q = iter.next();
      if (p.id != q.id && p.collision(q)) {
        return true;
      }
    }
    return false;
  }

  void handleCollision(EmojiParticle p, EmojiParticle q) {
    if (p.group == null) {
      if (q.group == null) {
        p.group = q.group = new EmojiGroup(currGroupIndex++, p, q);
      } else {
        q.group.particles.add(p);
        p.group = q.group;
      }
    } else {
      if (q.group == null) {
        p.group.particles.add(q);
        q.group = p.group;
      } else if (p.group.id != q.group.id) {
        Iterator<EmojiParticle> iter = q.group.particles.iterator();
        int i = 0;
        while (iter.hasNext ()) {
          EmojiParticle r = iter.next();
          r.group = p.group;
          p.group.particles.add(r);
        }
      }
    }

    if (p == player) p.group.leader = p;
    else if (q == player) p.group.leader = q;
  }

  void keyPressed() {
    player.keyPressed();
  }

  void keyReleased() {
    player.keyReleased();
  }
}
