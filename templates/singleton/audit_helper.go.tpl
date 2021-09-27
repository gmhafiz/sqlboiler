const (
	//AuditTableName = "{{.AuditTableName}}"
	AuditEnabled   = "{{.AuditEnabled}}"
)

var (
	ErrInvalidDatabaseDriver = fmt.Errorf("invalid database driver")
	ErrNoAuditSet            = fmt.Errorf("no audit is set from the request context")
)

type Event struct {
	ActorID    uint64    `db:"actor_id"`
	TableRowID uint64    `db:"table_row_id"`
	Table      string    `db:"table_name"`
	Action     Action    `db:"action"`
	OldValues  string    `db:"old_values"`
	NewValues  string    `db:"new_values"`
	HTTPMethod string    `db:"http_method"`
	URL        string    `db:"url"`
	IPAddress  string    `db:"ip_address"`
	UserAgent  string    `db:"user_agent"`
	CreatedAt  time.Time `db:"created_at"`
}

type Action string

const (
	Select Action = "select"
	Insert Action = "insert"
	Update Action = "update"
	Delete Action = "delete"
)

func Save(ctx context.Context, exec boil.ContextExecutor, action Action, event *Event) error {
    // `go generate` command inserts AuditTableName constant ot this query
    // mysql uses ? while postgres uses $1, $2, etc
    insert := fmt.Sprintf("INSERT INTO {{.AuditTableName}} (actor_id, table_row_id, table_name, action, old_values, new_values, http_method, url, ip_address, user_agent, created_at) VALUES(%s)", strmangle.Placeholders(dialect.UseIndexPlaceholders, 11, 1, 1))
    _, err := exec.ExecContext(ctx, insert,
        event.ActorID,
        event.TableRowID,
        event.Table,
        event.Action,
        event.OldValues,
        event.NewValues,
        event.HTTPMethod,
        event.URL,
        event.IPAddress,
        event.UserAgent,
        event.CreatedAt,
    )
    if err != nil {
        return err
    }

	return nil
}

func isExempted(exception []string, tableName string) bool {
	if tableName == "" {
		return true
	}
	for _, table := range exception {
		if tableName == table {
			return true
		}
	}

	return false
}
