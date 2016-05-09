local ffi = require 'ffi'

ffi.cdef[[

struct sd_buf {
	uint8_t *data;
	size_t size;
	size_t asize;
	size_t unit;
};

enum sd_mkd_autolink {
	MKDA_NOT_AUTOLINK,
	MKDA_NORMAL,
	MKDA_EMAIL,
};

enum sd_mkd_tableflags {
	MKD_TABLE_ALIGN_L = 1,
	MKD_TABLE_ALIGN_R = 2,
	MKD_TABLE_ALIGN_CENTER = 3,
	MKD_TABLE_ALIGNMASK = 3,
	MKD_TABLE_HEADER = 4
};

enum sd_mkd_extensions {
	MKDEXT_NO_INTRA_EMPHASIS = (1 << 0),
	MKDEXT_TABLES = (1 << 1),
	MKDEXT_FENCED_CODE = (1 << 2),
	MKDEXT_AUTOLINK = (1 << 3),
	MKDEXT_STRIKETHROUGH = (1 << 4),
	MKDEXT_SPACE_HEADERS = (1 << 6),
	MKDEXT_SUPERSCRIPT = (1 << 7),
	MKDEXT_LAX_SPACING = (1 << 8),
};

struct sd_callbacks {
	void (*blockcode)(struct sd_buf *ob, const struct sd_buf *text, const struct sd_buf *lang, void *opaque);
	void (*blockquote)(struct sd_buf *ob, const struct sd_buf *text, void *opaque);
	void (*blockhtml)(struct sd_buf *ob,const  struct sd_buf *text, void *opaque);
	void (*header)(struct sd_buf *ob, const struct sd_buf *text, int level, void *opaque);
	void (*hrule)(struct sd_buf *ob, void *opaque);
	void (*list)(struct sd_buf *ob, const struct sd_buf *text, int flags, void *opaque);
	void (*listitem)(struct sd_buf *ob, const struct sd_buf *text, int flags, void *opaque);
	void (*paragraph)(struct sd_buf *ob, const struct sd_buf *text, void *opaque);
	void (*table)(struct sd_buf *ob, const struct sd_buf *header, const struct sd_buf *body, void *opaque);
	void (*table_row)(struct sd_buf *ob, const struct sd_buf *text, void *opaque);
	void (*table_cell)(struct sd_buf *ob, const struct sd_buf *text, int flags, void *opaque);

	int (*autolink)(struct sd_buf *ob, const struct sd_buf *link, enum sd_mkd_autolink type, void *opaque);
	int (*codespan)(struct sd_buf *ob, const struct sd_buf *text, void *opaque);
	int (*double_emphasis)(struct sd_buf *ob, const struct sd_buf *text, void *opaque);
	int (*emphasis)(struct sd_buf *ob, const struct sd_buf *text, void *opaque);
	int (*image)(struct sd_buf *ob, const struct sd_buf *link, const struct sd_buf *title, const struct sd_buf *alt, void *opaque);
	int (*linebreak)(struct sd_buf *ob, void *opaque);
	int (*link)(struct sd_buf *ob, const struct sd_buf *link, const struct sd_buf *title, const struct sd_buf *content, void *opaque);
	int (*raw_html_tag)(struct sd_buf *ob, const struct sd_buf *tag, void *opaque);
	int (*triple_emphasis)(struct sd_buf *ob, const struct sd_buf *text, void *opaque);
	int (*strikethrough)(struct sd_buf *ob, const struct sd_buf *text, void *opaque);
	int (*superscript)(struct sd_buf *ob, const struct sd_buf *text, void *opaque);

	void (*entity)(struct sd_buf *ob, const struct sd_buf *entity, void *opaque);
	void (*normal_text)(struct sd_buf *ob, const struct sd_buf *text, void *opaque);

	void (*doc_header)(struct sd_buf *ob, void *opaque);
	void (*doc_footer)(struct sd_buf *ob, void *opaque);
};

struct sd_markdown;

struct sd_markdown * sd_markdown_new(
	unsigned int extensions,
	size_t max_nesting,
	const struct sd_callbacks *callbacks,
	void *opaque);

void sd_markdown_render(struct sd_buf *ob, const uint8_t *document, size_t doc_size, struct sd_markdown *md);

void sd_markdown_free(struct sd_markdown *md);

void sd_version(int *major, int *minor, int *revision);

/* buffer */

int sd_bufgrow(struct sd_buf *, size_t);
struct sd_buf *sd_bufnew(size_t) __attribute__ ((malloc));
const char *sd_bufcstr(struct sd_buf *);
int sd_bufprefix(const struct sd_buf *buf, const char *prefix);
void sd_bufput(struct sd_buf *, const void *, size_t);
void sd_bufputs(struct sd_buf *, const char *);
void sd_bufputc(struct sd_buf *, int);
void sd_bufrelease(struct sd_buf *);
void sd_bufreset(struct sd_buf *);
void sd_bufslurp(struct sd_buf *, size_t);

]]
