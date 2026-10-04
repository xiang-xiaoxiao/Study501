-- ============================================================================
-- AI 学习成长档案系统 - 数据库完整架构
-- 版本：V1.0
-- 数据库：PostgreSQL (Supabase)
-- 总表数：44 张
-- ============================================================================

-- ============================================================================
-- 一、核心层（8 张表）
-- ============================================================================

-- 1. student（学生档案表）
CREATE TABLE student (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nickname VARCHAR(100) NOT NULL,
  birth_date DATE,
  current_grade VARCHAR(20) NOT NULL,
  school VARCHAR(200),
  avatar_url VARCHAR(500),
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. app_settings（应用设置表）
CREATE TABLE app_settings (
  id INT PRIMARY KEY DEFAULT 1,
  current_student_id UUID REFERENCES student(id),
  ai_model VARCHAR(50),
  ocr_provider VARCHAR(50),
  notify_enabled BOOLEAN DEFAULT false,
  daily_goal INT DEFAULT 10,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. semester（学期表）
CREATE TABLE semester (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  semester_code VARCHAR(50) NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  start_date DATE,
  end_date DATE,
  is_current BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. learning_record（学习记录主表）
CREATE TABLE learning_record (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  subject_code VARCHAR(20) NOT NULL,
  record_type VARCHAR(30) NOT NULL,
  title VARCHAR(200),
  description TEXT,
  source VARCHAR(20),
  status VARCHAR(20) DEFAULT 'NEW',
  occurred_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. knowledge_point（知识点主表）
CREATE TABLE knowledge_point (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  point_code VARCHAR(100) UNIQUE NOT NULL,
  point_name VARCHAR(200) NOT NULL,
  subject_code VARCHAR(20) NOT NULL,
  parent_id UUID REFERENCES knowledge_point(id),
  level VARCHAR(20) NOT NULL,
  grade_code VARCHAR(20),
  description TEXT,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. knowledge_point_relation（知识点关联表）
CREATE TABLE knowledge_point_relation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id UUID NOT NULL REFERENCES knowledge_point(id),
  target_id UUID NOT NULL REFERENCES knowledge_point(id),
  relation_type VARCHAR(30) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. knowledge_mastery（知识点掌握度表）
CREATE TABLE knowledge_mastery (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  knowledge_point_id UUID NOT NULL REFERENCES knowledge_point(id),
  mastery_score INT DEFAULT 0,
  error_count INT DEFAULT 0,
  correct_count INT DEFAULT 0,
  review_count INT DEFAULT 0,
  training_streak INT DEFAULT 0,
  training_mastered BOOLEAN DEFAULT false,
  last_error_date DATE,
  last_review_date DATE,
  trend VARCHAR(20) DEFAULT 'NEW',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, knowledge_point_id)
);

-- 8. mistake_knowledge_point（错题-知识点关联表）
CREATE TABLE mistake_knowledge_point (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mistake_id UUID NOT NULL,
  knowledge_point_id UUID NOT NULL REFERENCES knowledge_point(id),
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 二、错误体系（5 张表）
-- ============================================================================

-- 9. mistake（错题主表）
CREATE TABLE mistake (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  subject_code VARCHAR(20) NOT NULL,
  grade_code VARCHAR(20),
  semester_id UUID REFERENCES semester(id),
  question_content TEXT NOT NULL,
  student_answer TEXT,
  teacher_answer TEXT,
  image_url VARCHAR(500),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. ai_analysis（AI 分析结果表）
CREATE TABLE ai_analysis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mistake_id UUID NOT NULL REFERENCES mistake(id),
  ai_category VARCHAR(20),
  ai_reason_id UUID,
  ai_confidence FLOAT,
  analysis_remark TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. mistake_review（人工审核表）
CREATE TABLE mistake_review (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mistake_id UUID NOT NULL REFERENCES mistake(id),
  review_status VARCHAR(20),
  final_category VARCHAR(20),
  final_reason_id UUID,
  reviewed_at TIMESTAMPTZ,
  review_comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. correction（订正答案表）
CREATE TABLE correction (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mistake_id UUID NOT NULL REFERENCES mistake(id),
  correction_type VARCHAR(20),
  correction_content TEXT,
  correction_file_url VARCHAR(500),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. error_reason_master（错因主表）
CREATE TABLE error_reason_master (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reason_code VARCHAR(50) UNIQUE NOT NULL,
  reason_name VARCHAR(200) NOT NULL,
  category_code VARCHAR(20) NOT NULL,
  subject_code VARCHAR(20),
  enabled BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 三、AI 管道体系（2 张表）
-- ============================================================================

-- 14. image_upload（图片上传记录表）
CREATE TABLE image_upload (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  image_url VARCHAR(500) NOT NULL,
  processed_url VARCHAR(500),
  upload_status VARCHAR(20) DEFAULT 'PENDING',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 15. ocr_result（OCR 识别结果表）
CREATE TABLE ocr_result (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  image_id UUID NOT NULL REFERENCES image_upload(id),
  raw_text TEXT,
  structured_data JSONB,
  ocr_provider VARCHAR(50),
  ocr_confidence FLOAT,
  process_time_ms INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 四、背诵体系（2 张表）
-- ============================================================================

-- 16. memory_point（记忆点表）
CREATE TABLE memory_point (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  subject_code VARCHAR(20) NOT NULL,
  knowledge_point_id UUID REFERENCES knowledge_point(id),
  memory_type VARCHAR(20) NOT NULL,
  title VARCHAR(200) NOT NULL,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 17. classical_text（古诗文扩展表）
CREATE TABLE classical_text (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  memory_point_id UUID NOT NULL REFERENCES memory_point(id),
  title VARCHAR(200) NOT NULL,
  author VARCHAR(100),
  dynasty VARCHAR(50),
  text_type VARCHAR(20),
  full_text TEXT,
  theme VARCHAR(100),
  key_techniques JSONB,
  famous_lines JSONB,
  context TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 五、单词体系（4 张表）
-- ============================================================================

-- 18. vocabulary（单词主表）
CREATE TABLE vocabulary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  word VARCHAR(200) NOT NULL,
  phonetic VARCHAR(100),
  meaning TEXT NOT NULL,
  example_sentence TEXT,
  grade_code VARCHAR(20),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 19. vocabulary_learning（单词学习记录表）
CREATE TABLE vocabulary_learning (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vocabulary_id UUID NOT NULL REFERENCES vocabulary(id),
  learning_date DATE NOT NULL,
  learning_type VARCHAR(20) NOT NULL,
  learning_result VARCHAR(20) NOT NULL,
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 20. vocabulary_mastery（单词掌握度表）
CREATE TABLE vocabulary_mastery (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  vocabulary_id UUID NOT NULL REFERENCES vocabulary(id),
  mastery_score INT DEFAULT 0,
  last_review_date DATE,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, vocabulary_id)
);

-- 21. vocabulary_error_type（单词错误类型表）
CREATE TABLE vocabulary_error_type (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vocabulary_learning_id UUID NOT NULL REFERENCES vocabulary_learning(id),
  error_type VARCHAR(30) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 六、阅读体系（2 张表）
-- ============================================================================

-- 22. reading_book（阅读书籍表）
CREATE TABLE reading_book (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  book_name VARCHAR(300) NOT NULL,
  author VARCHAR(200),
  category VARCHAR(30),
  cover_image_url VARCHAR(500),
  language VARCHAR(20),
  reading_status VARCHAR(20) DEFAULT 'PLANNED',
  start_date DATE,
  finish_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 23. reading_reflection（阅读感想表）
CREATE TABLE reading_reflection (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id UUID NOT NULL REFERENCES reading_book(id),
  favorite_character VARCHAR(200),
  favorite_sentence TEXT,
  biggest_takeaway TEXT,
  reflection TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 七、复习体系（2 张表）
-- ============================================================================

-- 24. review_plan（复习计划表）
CREATE TABLE review_plan (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  target_type VARCHAR(20) NOT NULL,
  target_id UUID NOT NULL,
  subject_code VARCHAR(20) NOT NULL,
  pass_streak INT DEFAULT 0,
  graduated BOOLEAN DEFAULT false,
  last_review_date DATE,
  review_status VARCHAR(20) DEFAULT 'ACTIVE',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 25. review_record（复习记录表）
CREATE TABLE review_record (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_plan_id UUID NOT NULL REFERENCES review_plan(id),
  review_date DATE NOT NULL,
  review_result VARCHAR(20) NOT NULL,
  review_comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 八、成绩追踪体系（2 张表）
-- ============================================================================

-- 26. exam（考试记录表）
CREATE TABLE exam (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  exam_name VARCHAR(200) NOT NULL,
  exam_date DATE NOT NULL,
  exam_type VARCHAR(20) NOT NULL,
  semester VARCHAR(50),
  total_score INT,
  remark TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 27. exam_score（考试成绩表）
CREATE TABLE exam_score (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id UUID NOT NULL REFERENCES exam(id),
  student_id UUID NOT NULL REFERENCES student(id),
  subject_code VARCHAR(20) NOT NULL,
  score FLOAT NOT NULL,
  max_score FLOAT DEFAULT 100,
  class_rank INT,
  grade_rank INT,
  remark TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(exam_id, subject_code)
);

-- ============================================================================
-- 九、成长体系（4 张表）
-- ============================================================================

-- 28. achievement_definition（勋章定义表）
CREATE TABLE achievement_definition (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  achievement_code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  category VARCHAR(20) NOT NULL,
  tier VARCHAR(20) NOT NULL,
  condition_type VARCHAR(50) NOT NULL,
  condition_value INT NOT NULL,
  icon_url VARCHAR(500),
  is_active BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 29. achievement_record（勋章获取记录表）
CREATE TABLE achievement_record (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  achievement_id UUID NOT NULL REFERENCES achievement_definition(id),
  earned_at TIMESTAMPTZ NOT NULL,
  trigger_event VARCHAR(50),
  trigger_value INT,
  is_notified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, achievement_id)
);

-- 30. student_growth（学生成长等级表）
CREATE TABLE student_growth (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  total_exp INT DEFAULT 0,
  growth_level INT DEFAULT 1,
  current_streak INT DEFAULT 0,
  max_streak INT DEFAULT 0,
  last_active_date DATE,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id)
);

-- 31. exp_log（经验值日志表）
CREATE TABLE exp_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  exp_amount INT NOT NULL,
  source_type VARCHAR(30) NOT NULL,
  source_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 十、表扬体系（2 张表）
-- ============================================================================

-- 32. praise_card（表扬卡表）
CREATE TABLE praise_card (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  card_type VARCHAR(20) NOT NULL,
  title VARCHAR(200) NOT NULL,
  content TEXT,
  highlight_behavior VARCHAR(200),
  source_event VARCHAR(50),
  source_id UUID,
  is_custom BOOLEAN DEFAULT false,
  status VARCHAR(20) DEFAULT 'ACTIVE',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 33. praise_template（表扬模板表）
CREATE TABLE praise_template (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_type VARCHAR(20) NOT NULL,
  trigger_event VARCHAR(50),
  title_template VARCHAR(200),
  body_template TEXT,
  footer_template TEXT,
  is_active BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 十一、AI 出题体系（3 张表）
-- ============================================================================

-- 34. question（题目表）
CREATE TABLE question (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_code VARCHAR(20) NOT NULL,
  grade_code VARCHAR(20),
  knowledge_point_id UUID REFERENCES knowledge_point(id),
  difficulty VARCHAR(20) NOT NULL,
  question_type VARCHAR(30) NOT NULL,
  question_content TEXT NOT NULL,
  options JSONB,
  answer TEXT NOT NULL,
  solution TEXT,
  skills_tested JSONB,
  source VARCHAR(20) DEFAULT 'AI_GENERATED',
  ai_model VARCHAR(50),
  review_status VARCHAR(20) DEFAULT 'PENDING',
  reviewed_by UUID,
  reviewed_at TIMESTAMPTZ,
  usage_count INT DEFAULT 0,
  correct_rate FLOAT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 35. quiz_session（训练会话表）
CREATE TABLE quiz_session (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  subject_code VARCHAR(20) NOT NULL,
  strategy VARCHAR(30) NOT NULL,
  question_count INT NOT NULL,
  status VARCHAR(20) DEFAULT 'IN_PROGRESS',
  correct_count INT DEFAULT 0,
  is_printed BOOLEAN DEFAULT false,
  printed_at TIMESTAMPTZ,
  print_mode VARCHAR(20),
  paper_size VARCHAR(10),
  graded_manually BOOLEAN DEFAULT false,
  graded_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 36. quiz_answer（做题记录表）
CREATE TABLE quiz_answer (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES quiz_session(id),
  question_id UUID NOT NULL REFERENCES question(id),
  student_id UUID NOT NULL REFERENCES student(id),
  student_answer TEXT,
  is_correct BOOLEAN DEFAULT false,
  time_spent_sec INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 十二、英语能力树（3 张表）
-- ============================================================================

-- 37. english_grammar_practice（语法练习记录表）
CREATE TABLE english_grammar_practice (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  learning_record_id UUID REFERENCES learning_record(id),
  student_id UUID NOT NULL REFERENCES student(id),
  knowledge_point_id UUID REFERENCES knowledge_point(id),
  practice_type VARCHAR(20) NOT NULL,
  total_questions INT,
  correct_count INT,
  error_patterns JSONB,
  source VARCHAR(50),
  image_url VARCHAR(500),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 38. english_reading_practice（英语阅读练习表）
CREATE TABLE english_reading_practice (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  learning_record_id UUID REFERENCES learning_record(id),
  student_id UUID NOT NULL REFERENCES student(id),
  title VARCHAR(300) NOT NULL,
  text_type VARCHAR(30),
  difficulty VARCHAR(20),
  word_count INT,
  total_questions INT,
  correct_count INT,
  new_words JSONB,
  skill_scores JSONB,
  source VARCHAR(50),
  image_url VARCHAR(500),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 39. english_writing（英语写作表）
CREATE TABLE english_writing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  learning_record_id UUID REFERENCES learning_record(id),
  student_id UUID NOT NULL REFERENCES student(id),
  title VARCHAR(300) NOT NULL,
  writing_type VARCHAR(30) NOT NULL,
  topic VARCHAR(200),
  word_count INT,
  content TEXT,
  image_url VARCHAR(500),
  grammar_errors JSONB,
  vocab_usage JSONB,
  ai_analysis JSONB,
  teacher_comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 十三、语文模块（2 张表）
-- ============================================================================

-- 40. chinese_reading_practice（语文阅读理解表）
CREATE TABLE chinese_reading_practice (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  learning_record_id UUID REFERENCES learning_record(id),
  student_id UUID NOT NULL REFERENCES student(id),
  title VARCHAR(300) NOT NULL,
  text_type VARCHAR(30),
  source VARCHAR(50),
  total_questions INT,
  correct_count INT,
  difficulty VARCHAR(20),
  error_analysis TEXT,
  image_url VARCHAR(500),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 41. chinese_essay（语文作文表）
CREATE TABLE chinese_essay (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  learning_record_id UUID REFERENCES learning_record(id),
  student_id UUID NOT NULL REFERENCES student(id),
  title VARCHAR(300) NOT NULL,
  essay_type VARCHAR(30) NOT NULL,
  topic VARCHAR(200),
  word_count INT,
  content TEXT,
  image_url VARCHAR(500),
  teacher_comment TEXT,
  teacher_score VARCHAR(20),
  highlights JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 十四、学习画像体系（2 张表）
-- ============================================================================

-- 42. student_profile（学生画像快照表）
CREATE TABLE student_profile (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  snapshot_date DATE NOT NULL,
  snapshot_type VARCHAR(20) NOT NULL,
  subject_scores JSONB,
  learning_style JSONB,
  error_profile JSONB,
  habit_profile JSONB,
  interest_profile JSONB,
  highlights JSONB,
  growth_areas JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 43. profile_report（画像报告表）
CREATE TABLE profile_report (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student(id),
  report_type VARCHAR(20) NOT NULL,
  period_start DATE,
  period_end DATE,
  report_data JSONB,
  ai_summary TEXT,
  pdf_url VARCHAR(500),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 索引优化
-- ============================================================================

-- 学生相关索引
CREATE INDEX idx_student_current ON app_settings(current_student_id);
CREATE INDEX idx_semester_student ON semester(student_id);
CREATE INDEX idx_learning_record_student ON learning_record(student_id, record_type);
CREATE INDEX idx_knowledge_mastery_student ON knowledge_mastery(student_id, knowledge_point_id);

-- 知识点相关索引
CREATE INDEX idx_knowledge_point_parent ON knowledge_point(parent_id);
CREATE INDEX idx_knowledge_point_subject ON knowledge_point(subject_code, level);
CREATE INDEX idx_kp_relation_source ON knowledge_point_relation(source_id);
CREATE INDEX idx_kp_relation_target ON knowledge_point_relation(target_id);

-- 错误体系索引
CREATE INDEX idx_mistake_student ON mistake(student_id, subject_code);
CREATE INDEX idx_mistake_semester ON mistake(semester_id);
CREATE INDEX idx_ai_analysis_mistake ON ai_analysis(mistake_id);
CREATE INDEX idx_mistake_review_mistake ON mistake_review(mistake_id);
CREATE INDEX idx_correction_mistake ON correction(mistake_id);
CREATE INDEX idx_mistake_kp_mistake ON mistake_knowledge_point(mistake_id);
CREATE INDEX idx_mistake_kp_kp ON mistake_knowledge_point(knowledge_point_id);

-- 背诵体系索引
CREATE INDEX idx_memory_point_student ON memory_point(student_id, subject_code);
CREATE INDEX idx_classical_text_memory ON classical_text(memory_point_id);

-- 单词体系索引
CREATE INDEX idx_vocabulary_student ON vocabulary(student_id);
CREATE INDEX idx_vocab_learning_vocab ON vocabulary_learning(vocabulary_id);
CREATE INDEX idx_vocab_mastery_student ON vocabulary_mastery(student_id, vocabulary_id);

-- 阅读体系索引
CREATE INDEX idx_reading_book_student ON reading_book(student_id, reading_status);
CREATE INDEX idx_reading_reflection_book ON reading_reflection(book_id);

-- 复习体系索引
CREATE INDEX idx_review_plan_student ON review_plan(student_id, graduated);
CREATE INDEX idx_review_plan_target ON review_plan(target_type, target_id);
CREATE INDEX idx_review_record_plan ON review_record(review_plan_id, review_date);

-- 成绩追踪索引
CREATE INDEX idx_exam_student ON exam(student_id, exam_date);
CREATE INDEX idx_exam_score_exam ON exam_score(exam_id);
CREATE INDEX idx_exam_score_student ON exam_score(student_id, subject_code);

-- 成长体系索引
CREATE INDEX idx_achievement_record_student ON achievement_record(student_id);
CREATE INDEX idx_student_growth_student ON student_growth(student_id);
CREATE INDEX idx_exp_log_student ON exp_log(student_id, created_at);

-- 表扬体系索引
CREATE INDEX idx_praise_card_student ON praise_card(student_id, status);
CREATE INDEX idx_praise_template_type ON praise_template(card_type, is_active);

-- AI 出题索引
CREATE INDEX idx_question_kp ON question(knowledge_point_id, difficulty);
CREATE INDEX idx_quiz_session_student ON quiz_session(student_id, subject_code);
CREATE INDEX idx_quiz_answer_session ON quiz_answer(session_id);

-- 英语能力树索引
CREATE INDEX idx_english_grammar_student ON english_grammar_practice(student_id);
CREATE INDEX idx_english_reading_student ON english_reading_practice(student_id);
CREATE INDEX idx_english_writing_student ON english_writing(student_id);

-- 语文模块索引
CREATE INDEX idx_chinese_reading_student ON chinese_reading_practice(student_id);
CREATE INDEX idx_chinese_essay_student ON chinese_essay(student_id);

-- 学习画像索引
CREATE INDEX idx_student_profile_student ON student_profile(student_id, snapshot_date);
CREATE INDEX idx_profile_report_student ON profile_report(student_id, report_type);

-- ============================================================================
-- 枚举类型说明（使用 VARCHAR + CHECK 约束或应用层验证）
-- ============================================================================

-- current_grade: GRADE_1~6, GRADE_7~9
-- subject_code: MATH, ENGLISH, CHINESE, PHYSICS, CHEMISTRY, BIOLOGY, HISTORY, GEOGRAPHY, POLITICS, SCIENCE
-- record_type: MISTAKE, MEMORY, VOCAB, READING, WRITING, REVIEW, GRAMMAR_PRACTICE, ENGLISH_READING, CHINESE_READING
-- level: SUBJECT, VOLUME, UNIT, CHAPTER, POINT
-- relation_type: PREREQUISITE, RELATED, EXTENDS
-- trend: IMPROVING, STABLE, DECLINING, NEW
-- memory_type: FACT, CONCEPT, LIST, TIMELINE, MAP
-- learning_type: LOOKUP, MEMORIZE, SPELLING, QUIZ, READING
-- learning_result: PASS, PARTIAL, FAIL
-- error_type: MEANING_ERROR, SPELLING_ERROR, COLLOCATION_ERROR, GRAMMAR_ERROR
-- reading_status: PLANNED, READING, FINISHED
-- category: LITERATURE, SCIENCE, HISTORY, BIOGRAPHY, NOVEL, ENGLISH, OTHER
-- review_result: PASS, PARTIAL, FAIL
-- target_type: MISTAKE, MEMORY, VOCAB, READING, WRITING
-- exam_type: MIDTERM, FINAL, MONTHLY, QUIZ, MOCK, OTHER
-- achievement category: MASTERY, PERSISTENCE, BREAKTHROUGH, EXPLORATION, HABIT
-- tier: BRONZE, SILVER, GOLD, PLATINUM, DIAMOND
-- card_type: MILESTONE, PERSISTENCE, BREAKTHROUGH, EFFORT, DAILY, CUSTOM
-- difficulty: BASIC, INTERMEDIATE, ADVANCED (题目) / EASY, MEDIUM, HARD (阅读)
-- question_type: CHOICE, FILL_BLANK, CALCULATION, WORD_PROBLEM, SHORT_ANSWER, TRANSLATION, CLOZE
-- strategy: WEAKNESS_FOCUS, REVIEW_PRACTICE, DAILY_MIX, PRE_REQUISITE, EXAM_PREP
-- practice_type: EXERCISE, TEST, HOMEWORK, ERROR_REVIEW
-- writing_type: SENTENCE, PARAGRAPH, ESSAY, LETTER, EMAIL, DIARY, PICTURE_WRITING, CONTINUATION
-- essay_type: NARRATIVE, EXPOSITORY, ARGUMENTATIVE, IMAGINATIVE, LETTER, DIARY, OTHER
-- text_type: NARRATIVE, EXPOSITORY, ARGUMENTATIVE, LITERARY, CLASSICAL, POETRY (语文阅读)
--            POEM, CI, PROSE (古诗文)
-- snapshot_type: DAILY, WEEKLY, MONTHLY
-- report_type: WEEKLY, MONTHLY, ANNUAL
-- source: EXAM, HOMEWORK, QUIZ, READING, PARENT
-- status: NEW, IN_PROGRESS, COMPLETED

-- ============================================================================
-- 结束
-- ============================================================================
