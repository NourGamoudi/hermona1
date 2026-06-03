import os

def update_forum_detail():
    path = r'c:\Users\asus\hermona1\lib\features\forum\presentation\screens\forum_detail_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    helper = '''
  String _translateCategory(String cat, BuildContext context) {
    final l = AppLocalizations.of(context);
    switch (cat) {
      case 'Général': return l.translate('cat_general');
      case 'Routine beauté': return l.translate('cat_routine');
      case 'Alimentation': return l.translate('cat_diet');
      case 'Hormones': return l.translate('cat_hormones');
      case 'Traitements': return l.translate('cat_treatments');
      case 'Témoignages': return l.translate('cat_stories');
      case 'Questions': return l.translate('cat_questions');
      default: return cat;
    }
  }
'''
    if '_translateCategory' not in content:
        content = content.replace('class _ForumDetailScreenState extends State<ForumDetailScreen> {', 'class _ForumDetailScreenState extends State<ForumDetailScreen> {' + helper)

    content = content.replace("Text(post['category'] ?? '',", "Text(_translateCategory(post['category'] ?? '', context),")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Updated forum_detail_screen.dart')

def update_create_post():
    path = r'c:\Users\asus\hermona1\lib\features\forum\presentation\screens\create_post_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    helper = '''
  String _translateCategory(String cat, BuildContext context) {
    final l = AppLocalizations.of(context);
    switch (cat) {
      case 'Général': return l.translate('cat_general');
      case 'Routine beauté': return l.translate('cat_routine');
      case 'Alimentation': return l.translate('cat_diet');
      case 'Hormones': return l.translate('cat_hormones');
      case 'Traitements': return l.translate('cat_treatments');
      case 'Témoignages': return l.translate('cat_stories');
      case 'Questions': return l.translate('cat_questions');
      default: return cat;
    }
  }
'''
    if '_translateCategory' not in content:
        content = content.replace('class _CreatePostScreenState extends State<CreatePostScreen> {', 'class _CreatePostScreenState extends State<CreatePostScreen> {' + helper)

    content = content.replace("child: Text(c, style: TextStyle(color: sel ? Colors.white : AppTheme.primary", "child: Text(_translateCategory(c, context), style: TextStyle(color: sel ? Colors.white : AppTheme.primary")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Updated create_post_screen.dart')

update_forum_detail()
update_create_post()
