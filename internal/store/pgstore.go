package store

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	"github.com/csonxx/ChronoCards/internal/model"
	_ "github.com/lib/pq"
)

// DBConfig 数据库配置
type DBConfig struct {
	Host     string
	Port     int
	User     string
	Password string
	DBName   string
}

// NewDBConfig 从环境变量或默认创建配置
func NewDBConfig() *DBConfig {
	return &DBConfig{
		Host:     getEnv("DB_HOST", "localhost"),
		Port:     5432,
		User:     getEnv("DB_USER", "chronocards"),
		Password: getEnv("DB_PASSWORD", "chronocards123"),
		DBName:   getEnv("DB_NAME", "chronocards"),
	}
}

func getEnv(key, defaultVal string) string {
	if val := ""; val != "" {
		return val
	}
	return defaultVal
}

// Connect 连接数据库
func Connect(cfg *DBConfig) (*sql.DB, error) {
	dsn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
		cfg.Host, cfg.Port, cfg.User, cfg.Password, cfg.DBName)

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("open db: %w", err)
	}

	// 连接池配置
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	// 测试连接
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("ping db: %w", err)
	}

	log.Println("Connected to PostgreSQL database")
	return db, nil
}

// PGStore PostgreSQL持久化存储
type PGStore struct {
	db *sql.DB
	*Store // 嵌入内存Store作为缓存
}

// NewPGStore 创建PostgreSQL存储
func NewPGStore(db *sql.DB) *PGStore {
	return &PGStore{
		db:    db,
		Store: NewStore(),
	}
}

// InitFromDB 从数据库加载初始数据到缓存
func (s *PGStore) InitFromDB() error {
	// 加载玩家
	rows, err := s.db.Query("SELECT id, name, level, exp, hp, max_hp, mp, max_mp, sword_intent, stamina, max_stamina, elem_wind, elem_fire, elem_water, elem_thunder, elem_ice, elem_poison, faction, rep_mingjiao, rep_zhengpai, rep_jinyiwei, created_at, updated_at FROM players")
	if err != nil {
		return fmt.Errorf("load players: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		p := &model.Player{}
		var faction sql.NullString
	var elemW, elemF, elemWa, elemT, elemI, elemPo sql.NullInt64
	var repM, repZ, repJ sql.NullInt64
		var swordIntent, stamina, maxStamina sql.NullInt64
		err := rows.Scan(&p.ID, &p.Name, &p.Level, &p.Exp, &p.HP, &p.MaxHP, &p.MP, &p.MaxMP, &swordIntent, &stamina, &maxStamina, &elemW, &elemF, &elemWa, &elemT, &elemI, &elemPo, &faction, &repM, &repZ, &repJ, &p.CreatedAt, &p.UpdatedAt)
		if err != nil {
			log.Printf("Error scanning player: %v", err)
			continue
		}
		if swordIntent.Valid {
			p.SwordIntent = int(swordIntent.Int64)
		}
		if stamina.Valid {
			p.Stamina = int(stamina.Int64)
		}
		if maxStamina.Valid {
			p.MaxStamina = int(maxStamina.Int64)
		}
		if faction.Valid {
			p.Faction = faction.String
		}
		p.ElementMastery = model.ElementMastery{
			Wind:    nullInt64ToInt(elemW),
			Fire:    nullInt64ToInt(elemF),
			Water:   nullInt64ToInt(elemWa),
			Thunder: nullInt64ToInt(elemT),
			Ice:     nullInt64ToInt(elemI),
			Poison:  nullInt64ToInt(elemPo),
		}
		p.Reputation = model.Reputation{
			Mingjiao:  nullInt64ToInt(repM),
			Zhengpai:  nullInt64ToInt(repZ),
			Jinyiwei:  nullInt64ToInt(repJ),
		}
		// 加载技能
		skillRows, _ := s.db.Query("SELECT skill_id FROM player_skills WHERE player_id = $1", p.ID)
		if skillRows != nil {
			for skillRows.Next() {
				var skillID string
				skillRows.Scan(&skillID)
				p.Skills = append(p.Skills, skillID)
			}
			skillRows.Close()
		}
		s.Store.players[p.ID] = p
	}

	// 加载卡组
	deckRows, err := s.db.Query("SELECT id, player_id, name, current_index, created_at FROM decks")
	if err == nil {
		defer deckRows.Close()
		for deckRows.Next() {
			d := &model.Deck{}
			deckRows.Scan(&d.ID, &d.PlayerID, &d.Name, &d.CurrentIndex, &d.CreatedAt)
			// 加载卡牌
			cardRows, _ := s.db.Query("SELECT card_id, card_type, title, description, priority FROM deck_cards WHERE deck_id = $1 ORDER BY position", d.ID)
			if cardRows != nil {
				for cardRows.Next() {
					c := &model.Card{}
					var desc sql.NullString
					var cardType string
					cardRows.Scan(&c.ID, &cardType, &c.Title, &desc, &c.Priority)
					c.Type = model.CardType(cardType)
					if desc.Valid {
						c.Description = desc.String
					}
					d.Cards = append(d.Cards, c)
				}
				cardRows.Close()
			}
			s.Store.decks[d.ID] = d
		}
	}

	log.Printf("Loaded %d players, %d decks from DB", len(s.Store.players), len(s.Store.decks))
	return nil
}

// ---- Player持久化 ----

// CreatePlayer 创建玩家（同时写DB）
func (s *PGStore) CreatePlayer(player *model.Player) {
	s.Store.CreatePlayer(player)
	go s.savePlayer(player)
}

func (s *PGStore) savePlayer(p *model.Player) {
	_, err := s.db.Exec(`
		INSERT INTO players (id, name, level, exp, hp, max_hp, mp, max_mp, sword_intent, stamina, max_stamina, elem_wind, elem_fire, elem_water, elem_thunder, elem_ice, elem_poison, faction, rep_mingjiao, rep_zhengpai, rep_jinyiwei, created_at, updated_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23)`,
		p.ID, p.Name, p.Level, p.Exp, p.HP, p.MaxHP, p.MP, p.MaxMP,
		p.SwordIntent, p.Stamina, p.MaxStamina,
		p.ElementMastery.Wind, p.ElementMastery.Fire, p.ElementMastery.Water,
		p.ElementMastery.Thunder, p.ElementMastery.Ice, p.ElementMastery.Poison,
		p.Faction, p.Reputation.Mingjiao, p.Reputation.Zhengpai, p.Reputation.Jinyiwei,
		p.CreatedAt, p.UpdatedAt,
	)
	if err != nil {
		log.Printf("Error saving player %s: %v", p.ID, err)
	}
}

// UpdatePlayer 更新玩家（同时写DB）
func (s *PGStore) UpdatePlayer(player *model.Player) {
	s.Store.UpdatePlayer(player)
	go s.savePlayer(player)
}

// GetPlayer 获取玩家（先读缓存）
func (s *PGStore) GetPlayer(id string) (*model.Player, bool) {
	return s.Store.GetPlayer(id)
}

// ---- Deck持久化 ----

// CreateDeck 创建卡组
func (s *PGStore) CreateDeck(deck *model.Deck) {
	s.Store.CreateDeck(deck)
	go s.saveDeck(deck)
}

func (s *PGStore) saveDeck(d *model.Deck) {
	_, err := s.db.Exec(`
		INSERT INTO decks (id, player_id, name, current_index, created_at)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (id) DO UPDATE SET name=$3, current_index=$4`,
		d.ID, d.PlayerID, d.Name, d.CurrentIndex, d.CreatedAt,
	)
	if err != nil {
		log.Printf("Error saving deck %s: %v", d.ID, err)
	}
}

// UpdateDeck 更新卡组
func (s *PGStore) UpdateDeck(deck *model.Deck) {
	s.Store.UpdateDeck(deck)
	go s.saveDeck(deck)
}

// GetDeck 获取卡组
func (s *PGStore) GetDeck(id string) (*model.Deck, bool) {
	return s.Store.GetDeck(id)
}

// ---- Dealer操作（只读，不持久化） ----

// GetDealer 获取发牌员
func (s *PGStore) GetDealer(id string) (*model.Dealer, bool) {
	return s.Store.GetDealer(id)
}

// ListDealers 列出所有发牌员
func (s *PGStore) ListDealers() []*model.Dealer {
	return s.Store.ListDealers()
}

// CreateDealer 创建发牌员
func (s *PGStore) CreateDealer(dealer *model.Dealer) {
	s.Store.CreateDealer(dealer)
	go func() {
		_, err := s.db.Exec(`
			INSERT INTO dealers (id, type, name, location, description, interaction_prompt, weight, created_at)
			VALUES ($1,$2,$3,$4,$5,$6,$7,NOW())
			ON CONFLICT (id) DO UPDATE SET name=$3, location=$4, description=$5`,
			dealer.ID, string(dealer.Type), dealer.Name, dealer.Location,
			dealer.Description, dealer.InteractionPrompt, dealer.Weight,
		)
		if err != nil {
			log.Printf("Error saving dealer: %v", err)
		}
	}()
}

func nullIntToInt(n sql.NullString) int {
	if n.Valid {
		var v int
		fmt.Sscanf(n.String, "%d", &v)
		return v
	}
	return 0
}

func nullInt64ToInt(n sql.NullInt64) int {
	if n.Valid {
		return int(n.Int64)
	}
	return 0
}
