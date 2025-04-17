import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'ru_RU': {
      // Общие
      'app_name': 'VKA Chat',
      'ok': 'OK',
      'cancel': 'Отмена',
      'save': 'Сохранить',
      'delete': 'Удалить',
      'edit': 'Редактировать',
      'search': 'Поиск',

      // Аутентификация
      'login': 'Вход',
      'register': 'Регистрация',
      'email': 'Email',
      'password': 'Пароль',
      'forgot_password': 'Забыли пароль?',
      'dont_have_account': 'Нет аккаунта?',
      'already_have_account': 'Уже есть аккаунт?',

      // Профиль
      'profile': 'Профиль',
      'settings': 'Настройки',
      'logout': 'Выйти',
      'change_password': 'Изменить пароль',
      'language': 'Язык',
      'theme': 'Тема',

      // Чат
      'chats': 'Чаты',
      'messages': 'Сообщения',
      'new_message': 'Новое сообщение',
      'type_message': 'Введите сообщение...',
      'send': 'Отправить',
      'online': 'В сети',
      'offline': 'Не в сети',
      'typing': 'Печатает...',
      'select_chat': 'Выберите чат',
      'menu': 'Меню',
      'contacts': 'Контакты',

      // Ошибки
      'error': 'Ошибка',
      'error_occurred': 'Произошла ошибка',
      'try_again': 'Попробовать снова',
      'no_internet': 'Нет подключения к интернету',
      'server_error': 'Ошибка сервера',

      // Успех
      'success': 'Успех',
      'saved': 'Сохранено',
      'updated': 'Обновлено',
      'deleted': 'Удалено',

      // Дополнительные настройки
      'notifications': 'Уведомления',
      'privacy': 'Конфиденциальность',
      'help_support': 'Помощь и поддержка',

      // Статусы прочтения сообщений
      'message_read': 'Прочитано',
      'message_not_read': 'Не прочитано',
      'message_no_reads': 'Сообщение еще никто не прочитал',
      'message_read_by': 'Прочитано пользователем',
      'message_read_at': 'Время прочтения',

      // Новые переводы для chats_view
      'no_messages': 'Нет сообщений',
      'no_chats': 'Нет чатов',
      'loading': 'Загрузка...',
      'today': 'Сегодня',
      'yesterday': 'Вчера',
      'this_week': 'На этой неделе',
      'this_month': 'В этом месяце',
      'older': 'Ранее',
      'group_chat': 'Групповой чат',
      'private_chat': 'Личный чат',
      'message_status': 'Статус сообщения',
      'message_sent': 'Отправлено',
      'message_delivered': 'Доставлено',

      // Настройки отправки сообщений
      'send_on_enter': 'Отправка по Enter',
      'send_on_enter_desc':
          'Отправлять сообщение по нажатию Enter (Shift+Enter для новой строки)',
    },
    'en_US': {
      // General
      'app_name': 'VKA Chat',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search',

      // Authentication
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'dont_have_account': 'Don\'t have an account?',
      'already_have_account': 'Already have an account?',

      // Profile
      'profile': 'Profile',
      'settings': 'Settings',
      'logout': 'Logout',
      'change_password': 'Change Password',
      'language': 'Language',
      'theme': 'Theme',

      // Chat
      'chats': 'Chats',
      'messages': 'Messages',
      'new_message': 'New Message',
      'type_message': 'Type a message...',
      'send': 'Send',
      'online': 'Online',
      'offline': 'Offline',
      'typing': 'Typing...',
      'select_chat': 'Select a chat',
      'menu': 'Menu',
      'contacts': 'Contacts',

      // Errors
      'error': 'Error',
      'error_occurred': 'An error occurred',
      'try_again': 'Try Again',
      'no_internet': 'No internet connection',
      'server_error': 'Server error',

      // Success
      'success': 'Success',
      'saved': 'Saved',
      'updated': 'Updated',
      'deleted': 'Deleted',

      // Additional Settings
      'notifications': 'Notifications',
      'privacy': 'Privacy',
      'help_support': 'Help & Support',

      // Message read status
      'message_read': 'Read',
      'message_not_read': 'Not Read',
      'message_no_reads': 'No one has read this message yet',
      'message_read_by': 'Read by',
      'message_read_at': 'Read at',

      // New translations for chats_view
      'no_messages': 'No messages',
      'no_chats': 'No chats',
      'loading': 'Loading...',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'this_week': 'This week',
      'this_month': 'This month',
      'older': 'Older',
      'group_chat': 'Group chat',
      'private_chat': 'Private chat',
      'message_status': 'Message status',
      'message_sent': 'Sent',
      'message_delivered': 'Delivered',

      // Message send settings
      'send_on_enter': 'Send on Enter',
      'send_on_enter_desc':
          'Send message on Enter key (Shift+Enter for new line)',
    },
  };
}
