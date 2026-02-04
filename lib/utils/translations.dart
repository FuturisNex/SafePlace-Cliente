import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class Translations {
  static String getText(BuildContext context, String key) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    final languageCode = locale.languageCode;

    switch (key) {
      // Tabs
      case 'search':
        return languageCode == 'pt' ? 'Buscar' : languageCode == 'es' ? 'Buscar' : 'Search';
      case 'nearby':
        return languageCode == 'pt' ? 'Próximos' : languageCode == 'es' ? 'Cercanos' : 'Nearby';
      case 'openNow':
        return languageCode == 'pt' ? 'Abertos' : languageCode == 'es' ? 'Abiertos' : 'Open Now';
      case 'achievements':
        return languageCode == 'pt' ? 'Conquista' : languageCode == 'es' ? 'Logros' : 'Achievements';
      case 'about':
        return languageCode == 'pt' ? 'Sobre' : languageCode == 'es' ? 'Acerca de' : 'About';

      // Menu
      case 'favorites':
        return languageCode == 'pt' ? 'Favoritos' : languageCode == 'es' ? 'Favoritos' : 'Favorites';
      case 'profile':
        return languageCode == 'pt' ? 'Perfil' : languageCode == 'es' ? 'Perfil' : 'Profile';
      case 'businessProfile':
        return languageCode == 'pt' ? 'Perfil Empresa' : languageCode == 'es' ? 'Perfil Empresa' : 'Business Profile';
      case 'account':
        return languageCode == 'pt' ? 'Conta' : languageCode == 'es' ? 'Cuenta' : 'Account';
      case 'login':
        return languageCode == 'pt' ? 'Login' : languageCode == 'es' ? 'Iniciar sesión' : 'Login';
      case 'pleaseLogin':
        return languageCode == 'pt' ? 'Por favor, faça login para adicionar favoritos' : languageCode == 'es' ? 'Por favor, inicia sesión para agregar favoritos' : 'Please login to add favorites';

      // Search
      case 'searchHint':
        return languageCode == 'pt' 
            ? 'Encontrar restaurantes, padarias, hotéis...' 
            : languageCode == 'es' 
                ? 'Encontrar restaurantes, panaderías, hoteles...'
                : 'Find restaurants, bakeries, hotels...';

      // Filters
      case 'celiac':
        return languageCode == 'pt' ? 'Sem glúten' : languageCode == 'es' ? 'Sin gluten' : 'Gluten Free';
      case 'lactoseFree':
        return languageCode == 'pt' ? 'Sem Lactose' : languageCode == 'es' ? 'Sin Lactosa' : 'Lactose Free';
      case 'nutFree':
        return languageCode == 'pt' ? 'Sem Amendoim' : languageCode == 'es' ? 'Sin Cacahuetes' : 'Nut Free';
      case 'vegan':
        return languageCode == 'pt' ? 'Vegano' : languageCode == 'es' ? 'Vegano' : 'Vegan';
      case 'halal':
        return languageCode == 'pt' ? 'Halal' : languageCode == 'es' ? 'Halal' : 'Halal';

      // Dietary Filters (para uso no getLabel)
      case 'dietaryCeliac':
        return languageCode == 'pt' ? 'Sem glúten' : languageCode == 'es' ? 'Sin gluten' : 'Gluten Free';
      case 'dietaryLactoseFree':
        return languageCode == 'pt' ? 'Sem Lactose' : languageCode == 'es' ? 'Sin Lactosa' : 'Lactose Free';
      case 'dietaryNutFree':
        return languageCode == 'pt' ? 'Sem Amendoim' : languageCode == 'es' ? 'Sin Cacahuetes' : 'Nut Free';
      case 'dietaryVegan':
        return languageCode == 'pt' ? 'Vegano' : languageCode == 'es' ? 'Vegano' : 'Vegan';
      case 'dietaryHalal':
        return languageCode == 'pt' ? 'Halal' : languageCode == 'es' ? 'Halal' : 'Halal';
      case 'dietaryAPLV':
        return languageCode == 'pt' ? 'APLV' : languageCode == 'es' ? 'APLV' : 'CMPA';
      case 'dietaryEggFree':
        return languageCode == 'pt' ? 'Sem Ovo' : languageCode == 'es' ? 'Sin Huevo' : 'Egg Free';
      case 'dietarySoyFree':
        return languageCode == 'pt' ? 'Sem Soja' : languageCode == 'es' ? 'Sin Soja' : 'Soy Free';
      case 'dietarySugarFree':
        return languageCode == 'pt' ? 'Sem Açúcar' : languageCode == 'es' ? 'Sin Azúcar' : 'Sugar Free';
      case 'dietaryVegetarian':
        return languageCode == 'pt' ? 'Vegetariano' : languageCode == 'es' ? 'Vegetariano' : 'Vegetarian';
      case 'dietaryOilseedFree':
        return languageCode == 'pt' ? 'Sem Oleaginosas' : languageCode == 'es' ? 'Sin Frutos Secos y Semillas Oleaginosas' : 'Oilseed Free';

      // Dialog
      case 'generateRoute':
        return languageCode == 'pt' ? 'Gerar Rota' : languageCode == 'es' ? 'Generar Ruta' : 'Generate Route';
      case 'cancel':
        return languageCode == 'pt' ? 'Cancelar' : languageCode == 'es' ? 'Cancelar' : 'Cancel';
      case 'close':
        return languageCode == 'pt' ? 'Fechar' : languageCode == 'es' ? 'Cerrar' : 'Close';
      case 'doYouWantToGo':
        return languageCode == 'pt' 
            ? 'Deseja gerar rota até este local?' 
            : languageCode == 'es' 
                ? '¿Deseas ir a este lugar?'
                : 'Do you want to go to this location?';

      // Messages
      case 'noEstablishments':
        return languageCode == 'pt' 
            ? 'Nenhum estabelecimento encontrado' 
            : languageCode == 'es' 
                ? 'No se encontraron establecimientos'
                : 'No establishments found';
      case 'clearFilters':
        return languageCode == 'pt' ? 'Limpar filtros' : languageCode == 'es' ? 'Limpiar filtros' : 'Clear filters';
      case 'advancedFilters':
        return languageCode == 'pt' ? 'Filtros Avançados' : languageCode == 'es' ? 'Filtros Avanzados' : 'Advanced Filters';
      case 'maxDistance':
        return languageCode == 'pt' ? 'Distância Máxima' : languageCode == 'es' ? 'Distancia Máxima' : 'Max Distance';
      case 'advancedFiltersPremiumDialogBody':
        return languageCode == 'pt'
            ? 'Os filtros avançados são exclusivos para usuários Premium.\n\n'
                'Torne-se Premium para acessar filtros por:\n'
                '• Tipo de restrição alimentar\n'
                '• Tipo de estabelecimento\n'
                '• Nível de selo (popular, intermediário, técnico)\n'
                '• Distância máxima\n'
                '• Avaliação mínima'
            : languageCode == 'es'
                ? 'Los filtros avanzados son exclusivos para usuarios Premium.\n\n'
                    'Hazte Premium para acceder a filtros por:\n'
                    '• Tipo de restricción alimentaria\n'
                    '• Tipo de establecimiento\n'
                    '• Nivel de sello (popular, intermedio, técnico)\n'
                    '• Distancia máxima\n'
                    '• Calificación mínima'
                : 'Advanced filters are exclusive to Premium users.\n\n'
                    'Become Premium to filter by:\n'
                    '• Dietary restriction type\n'
                    '• Establishment type\n'
                    '• Seal level (popular, intermediate, technical)\n'
                    '• Max distance\n'
                    '• Minimum rating';
      case 'minRating':
        return languageCode == 'pt' ? 'Avaliação Mínima' : languageCode == 'es' ? 'Calificación Mínima' : 'Minimum Rating';
      case 'any':
        return languageCode == 'pt' ? 'Qualquer' : languageCode == 'es' ? 'Cualquiera' : 'Any';
      case 'rating4Plus':
        return languageCode == 'pt' ? '4+ estrelas' : languageCode == 'es' ? '4+ estrellas' : '4+ stars';
      case 'rating45Plus':
        return languageCode == 'pt' ? '4.5+ estrelas' : languageCode == 'es' ? '4.5+ estrellas' : '4.5+ stars';
      case 'dietaryRestrictions':
        return languageCode == 'pt' ? 'Restrições Alimentares' : languageCode == 'es' ? 'Restricciones Alimentarias' : 'Dietary Restrictions';
      case 'establishmentType':
        return languageCode == 'pt' ? 'Tipo de Estabelecimento' : languageCode == 'es' ? 'Tipo de Establecimiento' : 'Establishment Type';
      case 'sealLevel':
        return languageCode == 'pt' ? 'Nível de Selo' : languageCode == 'es' ? 'Nivel de Sello' : 'Seal Level';
      case 'apply':
        return languageCode == 'pt' ? 'Aplicar' : languageCode == 'es' ? 'Aplicar' : 'Apply';
      case 'sortByDistance':
        return languageCode == 'pt' ? 'Mais Próximos' : languageCode == 'es' ? 'Más Cercanos' : 'Nearest';
      case 'sortByRating':
        return languageCode == 'pt' ? 'Melhor Avaliados' : languageCode == 'es' ? 'Mejor Calificados' : 'Best Rated';
      case 'sortByName':
        return languageCode == 'pt' ? 'Nome (A-Z)' : languageCode == 'es' ? 'Nombre (A-Z)' : 'Name (A-Z)';
      case 'sortByOpenFirst':
        return languageCode == 'pt' ? 'Abertos Primeiro' : languageCode == 'es' ? 'Abiertos Primero' : 'Open First';
      case 'share':
        return languageCode == 'pt' ? 'Compartilhar' : languageCode == 'es' ? 'Compartir' : 'Share';
      case 'addToFavorites':
        return languageCode == 'pt' ? 'Adicionar aos Favoritos' : languageCode == 'es' ? 'Agregar a Favoritos' : 'Add to Favorites';
      case 'errorSharing':
        return languageCode == 'pt' ? 'Erro ao compartilhar:' : languageCode == 'es' ? 'Error al compartir:' : 'Error sharing:';
      case 'totalEstablishments':
        return languageCode == 'pt' ? 'Total' : languageCode == 'es' ? 'Total' : 'Total';

      // App name
      case 'appName':
        return 'Prato Seguro'; // Mesmo em todos os idiomas
      case 'appSubtitle':
        return 'Safe Plate'; // Subtítulo curto da marca, mantido igual nos idiomas
      case 'appNameBusiness':
        return languageCode == 'pt'
            ? 'Prato Seguro Empresa'
            : languageCode == 'es'
                ? 'Prato Seguro Empresas'
                : 'Prato Seguro Business';
      case 'homeHeaderSubtitle':
        return languageCode == 'pt'
            ? 'Encontrar locais seguros'
            : languageCode == 'es'
                ? 'Encontrar lugares seguros'
                : 'Find safe places';

      // Establishment Profile
      case 'optionsAvailable':
        return languageCode == 'pt' ? 'Opções disponíveis:' : languageCode == 'es' ? 'Opciones disponibles:' : 'Available options:';
      case 'openNow':
        return languageCode == 'pt' ? 'Aberto agora' : languageCode == 'es' ? 'Abierto ahora' : 'Open now';
      case 'closed':
        return languageCode == 'pt' ? 'Fechado' : languageCode == 'es' ? 'Cerrado' : 'Closed';
      case 'goToLocation':
        return languageCode == 'pt' ? 'Ir até o local' : languageCode == 'es' ? 'Ir al lugar' : 'Go to location';
      case 'nearbyAlertTitle':
        return languageCode == 'pt'
            ? 'Você está perto de um lugar seguro!'
            : languageCode == 'es'
                ? 'Estás cerca de un lugar seguro.'
                : 'You are near a safe place!';
      case 'nearbyAlertSeeDetails':
        return languageCode == 'pt'
            ? 'Ver detalhes'
            : languageCode == 'es'
                ? 'Ver detalles'
                : 'See details';
      case 'estimatedWalkingTime':
        return languageCode == 'pt'
            ? 'Tempo estimado a pé:'
            : languageCode == 'es'
                ? 'Tiempo estimado a pie:'
                : 'Estimated walking time:';
      case 'reviews':
        return languageCode == 'pt' ? 'Avaliações' : languageCode == 'es' ? 'Reseñas' : 'Reviews';
      case 'noReviewsYet':
        return languageCode == 'pt' ? 'Nenhuma avaliação ainda' : languageCode == 'es' ? 'Aún no hay reseñas' : 'No reviews yet';
      case 'review':
        return languageCode == 'pt' ? 'avaliação' : languageCode == 'es' ? 'reseña' : 'review';
      case 'reviewsPlural':
        return languageCode == 'pt' ? 'avaliações' : languageCode == 'es' ? 'reseñas' : 'reviews';
      case 'loginToReview':
        return languageCode == 'pt' ? 'Faça login para deixar uma avaliação' : languageCode == 'es' ? 'Inicia sesión para dejar una reseña' : 'Login to leave a review';
      case 'alreadyReviewed':
        return languageCode == 'pt' ? 'Você já avaliou este estabelecimento' : languageCode == 'es' ? 'Ya has evaluado este establecimiento' : 'You have already reviewed this establishment';
      case 'leaveYourReview':
        return languageCode == 'pt' ? 'Deixe sua avaliação' : languageCode == 'es' ? 'Deja tu reseña' : 'Leave your review';
      case 'rating':
        return languageCode == 'pt' ? 'Avaliação' : languageCode == 'es' ? 'Calificación' : 'Rating';
      case 'comment':
        return languageCode == 'pt' ? 'Comentário' : languageCode == 'es' ? 'Comentario' : 'Comment';
      case 'tellYourExperience':
        return languageCode == 'pt' ? 'Conte sua experiência...' : languageCode == 'es' ? 'Cuenta tu experiencia...' : 'Tell your experience...';
      case 'pleaseWriteComment':
        return languageCode == 'pt' ? 'Por favor, escreva um comentário' : languageCode == 'es' ? 'Por favor, escribe un comentario' : 'Please write a comment';
      case 'commentMinLength':
        return languageCode == 'pt' ? 'O comentário deve ter pelo menos 10 caracteres' : languageCode == 'es' ? 'El comentario debe tener al menos 10 caracteres' : 'The comment must be at least 10 characters';
      case 'iReallyVisited':
        return languageCode == 'pt' ? 'Eu realmente visitei este estabelecimento' : languageCode == 'es' ? 'Realmente visité este establecimiento' : 'I really visited this establishment';
      case 'ownerCannotReview':
        return languageCode == 'pt' ? 'Você não pode avaliar seu próprio estabelecimento' : languageCode == 'es' ? 'No puedes evaluar tu propio establecimiento' : 'You cannot review your own establishment';
      case 'addedToFavorites':
        return languageCode == 'pt' ? 'adicionado aos favoritos!' : languageCode == 'es' ? 'agregado a favoritos!' : 'added to favorites!';
      case 'removedFromFavorites':
        return languageCode == 'pt' ? 'removido dos favoritos!' : languageCode == 'es' ? 'eliminado de favoritos!' : 'removed from favorites!';
      case 'errorSaving':
        return languageCode == 'pt' ? 'Erro ao salvar:' : languageCode == 'es' ? 'Error al guardar:' : 'Error saving:';
      case 'errorOpeningNavigation':
        return languageCode == 'pt' ? 'Não foi possível abrir navegação. Erro:' : languageCode == 'es' ? 'No se pudo abrir la navegación. Error:' : 'Could not open navigation. Error:';
      case 'errorGeneratingRoute':
        return languageCode == 'pt' ? 'Erro ao gerar rota:' : languageCode == 'es' ? 'Error al generar ruta:' : 'Error generating route:';

      // Difficulty Levels
      case 'difficultyPopular':
        return languageCode == 'pt' ? 'Popular' : languageCode == 'es' ? 'Popular' : 'Popular';
      case 'difficultyIntermediate':
        return languageCode == 'pt' ? 'Intermediário' : languageCode == 'es' ? 'Intermedio' : 'Intermediate';
      case 'difficultyTechnical':
        return languageCode == 'pt' ? 'Técnico' : languageCode == 'es' ? 'Técnico' : 'Technical';
      case 'difficultyPopularDescription':
        return languageCode == 'pt'
            ? 'Nível Popular: locais com requisitos básicos atendidos e opções acessíveis.'
            : languageCode == 'es'
                ? 'Nivel Popular: lugares con requisitos básicos cumplidos y opciones accesibles.'
                : 'Popular level: places with basic requirements met and accessible options.';
      case 'difficultyIntermediateDescription':
        return languageCode == 'pt'
            ? 'Nível Intermediário: maior atenção aos processos e às restrições alimentares.'
            : languageCode == 'es'
                ? 'Nivel Intermedio: mayor atención a los procesos y a las restricciones alimentarias.'
                : 'Intermediate level: greater attention to processes and dietary restrictions.';
      case 'difficultyTechnicalDescription':
        return languageCode == 'pt'
            ? 'Nível Técnico: foco alto em segurança alimentar e aderência técnica às restrições.'
            : languageCode == 'es'
                ? 'Nivel Técnico: alto enfoque en seguridad alimentaria y cumplimiento técnico de las restricciones.'
                : 'Technical level: strong focus on food safety and technical compliance with restrictions.';

      // Home Screen
      case 'myProfile':
        return languageCode == 'pt' ? 'Meu Perfil' : languageCode == 'es' ? 'Mi Perfil' : 'My Profile';
      case 'account':
        return languageCode == 'pt' ? 'Conta' : languageCode == 'es' ? 'Cuenta' : 'Account';
      case 'noUserLoggedIn':
        return languageCode == 'pt' ? 'Nenhum usuário logado' : languageCode == 'es' ? 'Ningún usuario conectado' : 'No user logged in';
      case 'businessAccount':
        return languageCode == 'pt' ? 'Conta Empresa' : languageCode == 'es' ? 'Cuenta Empresa' : 'Business Account';
      case 'userAccount':
        return languageCode == 'pt' ? 'Conta Usuário' : languageCode == 'es' ? 'Cuenta Usuario' : 'User Account';
      case 'accountType':
        return languageCode == 'pt' ? 'Tipo de Conta' : languageCode == 'es' ? 'Tipo de Cuenta' : 'Account Type';
      case 'business':
        return languageCode == 'pt' ? 'Empresa' : languageCode == 'es' ? 'Empresa' : 'Business';
      case 'user':
        return languageCode == 'pt' ? 'Usuário' : languageCode == 'es' ? 'Usuario' : 'User';
      case 'logout':
        return languageCode == 'pt' ? 'Sair da Conta' : languageCode == 'es' ? 'Cerrar Sesión' : 'Logout';
      case 'name':
        return languageCode == 'pt' ? 'Nome' : languageCode == 'es' ? 'Nombre' : 'Name';
      case 'noName':
        return languageCode == 'pt' ? 'Sem nome' : languageCode == 'es' ? 'Sin nombre' : 'No name';
      case 'dashboard':
        return languageCode == 'pt' ? 'Dashboard' : languageCode == 'es' ? 'Panel' : 'Dashboard';

      // Business Dashboard
      case 'businessDashboard':
        return languageCode == 'pt' ? 'Painel da Empresa' : languageCode == 'es' ? 'Panel de la Empresa' : 'Business Dashboard';
      case 'registerEstablishment':
        return languageCode == 'pt' ? 'Cadastrar Estabelecimento' : languageCode == 'es' ? 'Registrar Establecimiento' : 'Register Establishment';
      case 'restrictedAccess':
        return languageCode == 'pt' ? 'Acesso restrito a empresas' : languageCode == 'es' ? 'Acceso restringido a empresas' : 'Restricted access to businesses';
      case 'registeredEstablishments':
        return languageCode == 'pt' ? 'Estabelecimentos Cadastrados' : languageCode == 'es' ? 'Establecimientos Registrados' : 'Registered Establishments';
      case 'noEstablishmentsRegistered':
        return languageCode == 'pt' ? 'Nenhum estabelecimento cadastrado ainda' : languageCode == 'es' ? 'Aún no hay establecimientos registrados' : 'No establishments registered yet';
      case 'basicInformation':
        return languageCode == 'pt' ? 'Informações Básicas' : languageCode == 'es' ? 'Información Básica' : 'Basic Information';
      case 'category':
        return languageCode == 'pt' ? 'Categoria' : languageCode == 'es' ? 'Categoría' : 'Category';
      case 'address':
        return languageCode == 'pt' ? 'Endereço' : languageCode == 'es' ? 'Dirección' : 'Address';
      case 'toDefine':
        return languageCode == 'pt' ? 'A definir' : languageCode == 'es' ? 'Por definir' : 'To define';
      case 'status':
        return languageCode == 'pt' ? 'Status' : languageCode == 'es' ? 'Estado' : 'Status';
      case 'open':
        return languageCode == 'pt' ? 'Aberto' : languageCode == 'es' ? 'Abierto' : 'Open';
      case 'editInformation':
        return languageCode == 'pt' ? 'Editar Informações' : languageCode == 'es' ? 'Editar Información' : 'Edit Information';
      case 'editFeatureInDevelopment':
        return languageCode == 'pt' ? 'Funcionalidade de edição em desenvolvimento' : languageCode == 'es' ? 'Funcionalidad de edición en desarrollo' : 'Edit feature in development';
      case 'reviewsTab':
        return languageCode == 'pt' ? 'Avaliações' : languageCode == 'es' ? 'Reseñas' : 'Reviews';
      case 'averageRating':
        return languageCode == 'pt' ? 'Avaliação Média' : languageCode == 'es' ? 'Calificación Promedio' : 'Average Rating';
      case 'totalReviews':
        return languageCode == 'pt' ? 'Total de Avaliações' : languageCode == 'es' ? 'Total de Reseñas' : 'Total Reviews';
      case 'noReviews':
        return languageCode == 'pt' ? 'Nenhuma avaliação ainda' : languageCode == 'es' ? 'Aún no hay reseñas' : 'No reviews yet';
      case 'businessInstitutionalPitchTitle':
        return languageCode == 'pt'
            ? 'Por que anunciar no Prato Seguro?'
            : languageCode == 'es'
                ? '¿Por qué anunciar en Prato Seguro?'
                : 'Why advertise on Prato Seguro?';
      case 'businessInstitutionalPitchDescription':
        return languageCode == 'pt'
            ? 'Anúncio gratuito para todas as empresas e planos pagos com mais visibilidade, fotos em destaque e posição de topo.'
            : languageCode == 'es'
                ? 'Anuncio gratuito para todas las empresas y planes de pago con más visibilidad, fotos destacadas y posición superior.'
                : 'Free listing for all businesses and paid plans with more visibility, featured photos and top position.';
      case 'businessPlans':
        return languageCode == 'pt'
            ? 'Planos para Empresas'
            : languageCode == 'es'
                ? 'Planes para Empresas'
                : 'Business Plans';
      case 'basicPlan':
        return languageCode == 'pt' ? 'Básico' : languageCode == 'es' ? 'Básico' : 'Basic';
      case 'intermediatePlan':
        return languageCode == 'pt' ? 'Intermediário' : languageCode == 'es' ? 'Intermedio' : 'Intermediate';
      case 'goldPlan':
        return languageCode == 'pt' ? 'Ouro' : languageCode == 'es' ? 'Oro' : 'Gold';
      case 'talkOnWhatsApp':
        return languageCode == 'pt' ? 'Falar no WhatsApp' : languageCode == 'es' ? 'Hablar por WhatsApp' : 'Talk on WhatsApp';
      case 'whatsAppContactForPlans':
        return languageCode == 'pt'
            ? 'Fale com nossa equipe pelo WhatsApp para aderir a um plano ou tirar dúvidas.'
            : languageCode == 'es'
                ? 'Habla con nuestro equipo por WhatsApp para adherirte a un plan o aclarar dudas.'
                : 'Talk to our team on WhatsApp to join a plan or ask questions.';
      case 'iWantToParticipate':
        return languageCode == 'pt'
            ? 'Quero fazer parte'
            : languageCode == 'es'
                ? 'Quiero participar'
                : 'I want to join';
      case 'investorPitchTitle':
        return languageCode == 'pt'
            ? 'Para investidores e parceiros'
            : languageCode == 'es'
                ? 'Para inversionistas y socios'
                : 'For investors and partners';
      case 'investorPitchDescription':
        return languageCode == 'pt'
            ? 'Conheça a visão de futuro do Prato Seguro, métricas e oportunidades para apoiar o crescimento do projeto.'
            : languageCode == 'es'
                ? 'Conoce la visión de futuro de Prato Seguro, métricas y oportunidades para apoyar el crecimiento del proyecto.'
                : 'Learn about Prato Seguro\'s vision, metrics and opportunities to support the project\'s growth.';
      case 'investorPitchButton':
        return languageCode == 'pt'
            ? 'Ver pitch para investidores'
            : languageCode == 'es'
                ? 'Ver pitch para inversionistas'
                : 'See investor pitch';
      case 'investorPitchWhatsAppMessage':
        return languageCode == 'pt'
            ? 'Olá! Gostaria de falar sobre investimento e parcerias com o Prato Seguro.'
            : languageCode == 'es'
                ? '¡Hola! Me gustaría hablar sobre inversión y alianzas con Prato Seguro.'
                : 'Hi! I would like to talk about investment and partnerships with Prato Seguro.';
      case 'technicalCertification':
        return languageCode == 'pt'
            ? 'Certificação Técnica'
            : languageCode == 'es'
                ? 'Certificación Técnica'
                : 'Technical Certification';
      case 'technicalCertificationDescription':
        return languageCode == 'pt'
            ? 'Receba o selo de certificação técnica Prato Seguro com agenda direta com nutricionista.'
            : languageCode == 'es'
                ? 'Recibe el sello de certificación técnica Prato Seguro con agenda directa con nutricionista.'
                : 'Get the Prato Seguro technical certification badge with direct scheduling with a nutritionist.';
      case 'technicalCertificationWhatsAppMessage':
        return languageCode == 'pt'
            ? 'Olá! Gostaria de solicitar certificação técnica para meu estabelecimento no Prato Seguro.'
            : languageCode == 'es'
                ? '¡Hola! Me gustaría solicitar la certificación técnica para mi establecimiento en Prato Seguro.'
                : 'Hi! I would like to request technical certification for my business on Prato Seguro.';
      case 'businessPlansWhatsAppMessage':
        return languageCode == 'pt'
            ? 'Olá! Gostaria de falar sobre os planos pagos para empresas no Prato Seguro.'
            : languageCode == 'es'
                ? '¡Hola! Me gustaría hablar sobre los planes pagos para empresas en Prato Seguro.'
                : 'Hi! I would like to talk about business plans on Prato Seguro.';
      case 'certificationStatusLabel':
        return languageCode == 'pt'
            ? 'Status da certificação'
            : languageCode == 'es'
                ? 'Estado de la certificación'
                : 'Certification status';
      case 'certificationStatusNone':
        return languageCode == 'pt'
            ? 'Sem certificação'
            : languageCode == 'es'
                ? 'Sin certificación'
                : 'No certification';
      case 'certificationStatusPending':
        return languageCode == 'pt'
            ? 'Solicitada (pendente)'
            : languageCode == 'es'
                ? 'Solicitada (pendiente)'
                : 'Requested (pending)';
      case 'certificationStatusScheduled':
        return languageCode == 'pt'
            ? 'Agendada'
            : languageCode == 'es'
                ? 'Agendada'
                : 'Scheduled';
      case 'certificationStatusCertified':
        return languageCode == 'pt'
            ? 'Certificado'
            : languageCode == 'es'
                ? 'Certificado'
                : 'Certified';
      case 'certifiedPlaceBadge':
        return languageCode == 'pt'
            ? 'Local Certificado Prato Seguro'
            : languageCode == 'es'
                ? 'Local Certificado Prato Seguro'
                : 'Prato Seguro Certified Place';
      case 'trustSafetyTitle':
        return languageCode == 'pt'
            ? 'Confiança e segurança alimentar'
            : languageCode == 'es'
                ? 'Confianza y seguridad alimentaria'
                : 'Food safety & trust';
      case 'activity':
        return languageCode == 'pt'
            ? 'Atividade'
            : languageCode == 'es'
                ? 'Actividad'
                : 'Activity';        
      case 'trustCertificationCertified':
        return languageCode == 'pt'
            ? 'Este local possui certificação técnica Prato Seguro.'
            : languageCode == 'es'
                ? 'Este lugar cuenta con certificación técnica Prato Seguro.'
                : 'This place has Prato Seguro technical certification.';
      case 'trustCertificationInProgress':
        return languageCode == 'pt'
            ? 'Este local está em processo de certificação técnica.'
            : languageCode == 'es'
                ? 'Este lugar está en proceso de certificación técnica.'
                : 'This place is in technical certification process.';
      case 'trustCertificationNone':
        return languageCode == 'pt'
            ? 'Ainda sem certificação técnica formal, mas já avaliado pela comunidade.'
            : languageCode == 'es'
                ? 'Aún sin certificación técnica formal, pero ya evaluado por la comunidad.'
                : 'No formal technical certification yet, but already reviewed by the community.';
      case 'lastInspectionLabel':
        return languageCode == 'pt'
            ? 'Última inspeção sanitária'
            : languageCode == 'es'
                ? 'Última inspección sanitaria'
                : 'Last health inspection';
      case 'dataProtectionMessage':
        return languageCode == 'pt'
            ? 'Nós protegemos seus dados. Leia nossa política de privacidade.'
            : languageCode == 'es'
                ? 'Protegemos tus datos. Lee nuestra política de privacidad.'
                : 'We protect your data. Read our privacy policy.';
      case 'requestTechnicalCertification':
        return languageCode == 'pt'
            ? 'Solicitar certificação técnica'
            : languageCode == 'es'
                ? 'Solicitar certificación técnica'
                : 'Request technical certification';
      case 'certificationRequestSent':
        return languageCode == 'pt'
            ? 'Solicitação de certificação técnica enviada com sucesso! ✅'
            : languageCode == 'es'
                ? 'Solicitud de certificación técnica enviada con éxito! ✅'
                : 'Technical certification request sent successfully! ✅';
      // Review Form
      case 'sendReview':
        return languageCode == 'pt' ? 'Enviar Avaliação' : languageCode == 'es' ? 'Enviar Reseña' : 'Send Review';
      case 'mustBeLoggedIn':
        return languageCode == 'pt' ? 'Você precisa estar logado para avaliar' : languageCode == 'es' ? 'Debes iniciar sesión para evaluar' : 'You must be logged in to review';
      case 'reviewSentSuccessfully':
        return languageCode == 'pt' ? 'Avaliação enviada com sucesso! ✅' : languageCode == 'es' ? '¡Reseña enviada con éxito! ✅' : 'Review sent successfully! ✅';
      case 'errorSendingReview':
        return languageCode == 'pt' ? 'Erro ao enviar avaliação. Tente novamente.' : languageCode == 'es' ? 'Error al enviar reseña. Inténtalo de nuevo.' : 'Error sending review. Try again.';

      // Login/Signup
      case 'doLogin':
        return languageCode == 'pt' ? 'Fazer Login' : languageCode == 'es' ? 'Iniciar Sesión' : 'Login';
      case 'fillAllFields':
        return languageCode == 'pt' ? 'Por favor, preencha todos os campos' : languageCode == 'es' ? 'Por favor, completa todos los campos' : 'Please fill in all fields';
      case 'loginAs':
        return languageCode == 'pt' ? 'Login realizado como' : languageCode == 'es' ? 'Sesión iniciada como' : 'Logged in as';
      case 'loginError':
        return languageCode == 'pt' ? 'Erro ao fazer login. Tente novamente.' : languageCode == 'es' ? 'Error al iniciar sesión. Inténtalo de nuevo.' : 'Error logging in. Try again.';

      // Establishment Detail Screen
      case 'back':
        return languageCode == 'pt' ? 'Voltar' : languageCode == 'es' ? 'Volver' : 'Back';

      // Map
      case 'configureMapboxToken':
        return languageCode == 'pt' ? 'Configure Mapbox Token' : languageCode == 'es' ? 'Configurar Token de Mapbox' : 'Configure Mapbox Token';
      case 'showingEstablishmentsInBrazil':
        return languageCode == 'pt' ? 'Mostrando estabelecimentos no Brasil' : languageCode == 'es' ? 'Mostrando establecimientos en Brasil' : 'Showing establishments in Brazil';

      // Additional translations
      case 'add':
        return languageCode == 'pt' ? 'Adicionar' : languageCode == 'es' ? 'Agregar' : 'Add';
      case 'menu':
        return languageCode == 'pt' ? 'Cardápio' : languageCode == 'es' ? 'Menú' : 'Menu';
      case 'addDish':
        return languageCode == 'pt' ? 'Adicionar Prato' : languageCode == 'es' ? 'Agregar Plato' : 'Add Dish';
      case 'addDishFeatureInDevelopment':
        return languageCode == 'pt' ? 'Funcionalidade de adicionar prato em desenvolvimento' : languageCode == 'es' ? 'Funcionalidad de agregar plato en desarrollo' : 'Add dish feature in development';

      // Review Card
      case 'anonymousUser':
        return languageCode == 'pt' ? 'Usuário Anônimo' : languageCode == 'es' ? 'Usuario Anónimo' : 'Anonymous User';
      case 'verified':
        return languageCode == 'pt' ? 'Verificado' : languageCode == 'es' ? 'Verificado' : 'Verified';

      // Favorites Screen
      case 'favoritesTitle':
        return languageCode == 'pt' ? 'Favoritos' : languageCode == 'es' ? 'Favoritos' : 'Favorites';
      case 'favorite':
        return languageCode == 'pt' ? 'favorito' : languageCode == 'es' ? 'favorito' : 'favorite';
      case 'favoritesPlural':
        return languageCode == 'pt' ? 'favoritos' : languageCode == 'es' ? 'favoritos' : 'favorites';
      case 'noFavoritesYet':
        return languageCode == 'pt' ? 'Nenhum favorito ainda' : languageCode == 'es' ? 'Aún no hay favoritos' : 'No favorites yet';
      case 'addRestaurantsToFavorites':
        return languageCode == 'pt' ? 'Adicione restaurantes aos favoritos para vê-los aqui' : languageCode == 'es' ? 'Agrega restaurantes a favoritos para verlos aquí' : 'Add restaurants to favorites to see them here';
      case 'removedFromFavorites':
        return languageCode == 'pt' ? 'removido dos favoritos' : languageCode == 'es' ? 'eliminado de favoritos' : 'removed from favorites';

      // Time ago translations
      case 'yearAgo':
        return languageCode == 'pt' ? 'ano atrás' : languageCode == 'es' ? 'año atrás' : 'year ago';
      case 'yearsAgo':
        return languageCode == 'pt' ? 'anos atrás' : languageCode == 'es' ? 'años atrás' : 'years ago';
      case 'monthAgo':
        return languageCode == 'pt' ? 'mês atrás' : languageCode == 'es' ? 'mes atrás' : 'month ago';
      case 'monthsAgo':
        return languageCode == 'pt' ? 'meses atrás' : languageCode == 'es' ? 'meses atrás' : 'months ago';
      case 'dayAgo':
        return languageCode == 'pt' ? 'dia atrás' : languageCode == 'es' ? 'día atrás' : 'day ago';
      case 'daysAgo':
        return languageCode == 'pt' ? 'dias atrás' : languageCode == 'es' ? 'días atrás' : 'days ago';
      case 'hourAgo':
        return languageCode == 'pt' ? 'hora atrás' : languageCode == 'es' ? 'hora atrás' : 'hour ago';
      case 'hoursAgo':
        return languageCode == 'pt' ? 'horas atrás' : languageCode == 'es' ? 'horas atrás' : 'hours ago';
      case 'minuteAgo':
        return languageCode == 'pt' ? 'minuto atrás' : languageCode == 'es' ? 'minuto atrás' : 'minute ago';
      case 'minutesAgo':
        return languageCode == 'pt' ? 'minutos atrás' : languageCode == 'es' ? 'minutos atrás' : 'minutes ago';
      case 'now':
        return languageCode == 'pt' ? 'Agora' : languageCode == 'es' ? 'Ahora' : 'Now';

      // Categories
      case 'categoryRestaurant':
        return languageCode == 'pt' ? 'Restaurante' : languageCode == 'es' ? 'Restaurante' : 'Restaurant';
      case 'categoryBakery':
        return languageCode == 'pt' ? 'Padaria' : languageCode == 'es' ? 'Panadería' : 'Bakery';
      case 'categoryHotel':
        return languageCode == 'pt' ? 'Hotel' : languageCode == 'es' ? 'Hotel' : 'Hotel';
      case 'categoryCafe':
        return languageCode == 'pt' ? 'Café' : languageCode == 'es' ? 'Café' : 'Cafe';
      case 'categoryMarket':
        return languageCode == 'pt' ? 'Mercado' : languageCode == 'es' ? 'Mercado' : 'Market';
      case 'categoryOther':
        return languageCode == 'pt' ? 'Outro' : languageCode == 'es' ? 'Otro' : 'Other';

      // Menu/Dishes
      case 'menuDishes':
        return languageCode == 'pt' ? 'Pratos do Cardápio' : languageCode == 'es' ? 'Platos del Menú' : 'Menu Dishes';
      case 'noDishesRegistered':
        return languageCode == 'pt' ? 'Nenhum prato cadastrado' : languageCode == 'es' ? 'Ningún plato registrado' : 'No dishes registered';
      case 'uploadPhotoFeatureInDevelopment':
        return languageCode == 'pt' ? 'Funcionalidade de upload de foto em desenvolvimento' : languageCode == 'es' ? 'Funcionalidad de subir foto en desarrollo' : 'Upload photo feature in development';

      // Language selector
      case 'language':
        return languageCode == 'pt' ? 'Idioma' : languageCode == 'es' ? 'Idioma' : 'Language';
      case 'createAccount':
        return languageCode == 'pt' ? 'Criar Conta' : languageCode == 'es' ? 'Crear Cuenta' : 'Create Account';
      case 'password':
        return languageCode == 'pt' ? 'Senha' : languageCode == 'es' ? 'Contraseña' : 'Password';
      case 'or':
        return languageCode == 'pt' ? 'ou' : languageCode == 'es' ? 'o' : 'or';
      case 'continueWithGoogle':
        return languageCode == 'pt' ? 'Continuar com Google' : languageCode == 'es' ? 'Continuar con Google' : 'Continue with Google';
      case 'continueWithFacebook':
        return languageCode == 'pt'
            ? 'Continuar com Facebook'
            : languageCode == 'es'
                ? 'Continuar con Facebook'
                : 'Continue with Facebook';
      case 'continueWithApple':
        return languageCode == 'pt'
            ? 'Continuar com Apple'
            : languageCode == 'es'
                ? 'Continuar con Apple'
                : 'Continue with Apple';
      case 'dontHaveAccount':
        return languageCode == 'pt' ? 'Não tem uma conta? ' : languageCode == 'es' ? '¿No tienes una cuenta? ' : "Don't have an account? ";
      case 'signUp':
        return languageCode == 'pt' ? 'Cadastrar-se' : languageCode == 'es' ? 'Registrarse' : 'Sign Up';
      case 'termsOfUse':
        return languageCode == 'pt' ? 'Termos de Uso' : languageCode == 'es' ? 'Términos de Uso' : 'Terms of Use';
      case 'privacyPolicy':
        return languageCode == 'pt' ? 'Política de Privacidade' : languageCode == 'es' ? 'Política de Privacidad' : 'Privacy Policy';
      case 'loginAs':
        return languageCode == 'pt' ? 'Login realizado como' : languageCode == 'es' ? 'Inicio de sesión realizado como' : 'Login as';
      case 'googleLoginAs':
        return languageCode == 'pt' ? 'Login com Google realizado como' : languageCode == 'es' ? 'Inicio de sesión con Google realizado como' : 'Google login as';
      case 'loginError':
        return languageCode == 'pt' ? 'Erro ao fazer login. Tente novamente.' : languageCode == 'es' ? 'Error al iniciar sesión. Inténtalo de nuevo.' : 'Error logging in. Try again.';
      case 'forgotPassword':
        return languageCode == 'pt'
            ? 'Esqueceu a senha?'
            : languageCode == 'es'
                ? '¿Olvidaste tu contraseña?'
                : 'Forgot your password?';
      case 'passwordResetEmailSent':
        return languageCode == 'pt'
            ? 'Enviamos um link de recuperação para seu email.'
            : languageCode == 'es'
                ? 'Hemos enviado un enlace de recuperación a tu correo.'
                : 'We sent a password reset link to your email.';
      case 'passwordResetEmailError':
        return languageCode == 'pt'
            ? 'Não foi possível enviar o email de recuperação. Tente novamente.'
            : languageCode == 'es'
                ? 'No fue posible enviar el correo de recuperación. Inténtalo de nuevo.'
                : 'Could not send the recovery email. Please try again.';
      case 'loginEnterEmail':
        return languageCode == 'pt'
            ? 'Por favor, informe o email.'
            : languageCode == 'es'
                ? 'Por favor, ingresa el correo electrónico.'
                : 'Please enter your email.';
      case 'loginEnterValidEmail':
        return languageCode == 'pt'
            ? 'Por favor, informe um email válido.'
            : languageCode == 'es'
                ? 'Por favor, ingresa un correo electrónico válido.'
                : 'Please enter a valid email.';
      case 'loginEnterPassword':
        return languageCode == 'pt'
            ? 'Por favor, informe a senha.'
            : languageCode == 'es'
                ? 'Por favor, ingresa la contraseña.'
                : 'Please enter your password.';
      case 'loginChooseProfile':
        return languageCode == 'pt'
            ? 'Como você quer entrar hoje?'
            : languageCode == 'es'
                ? '¿Cómo quieres entrar hoy?'
                : 'How do you want to sign in today?';
      case 'userLoginTitle':
        return languageCode == 'pt'
            ? 'Sou cliente'
            : languageCode == 'es'
                ? 'Soy cliente'
                : 'I am a customer';
      case 'userLoginSubtitle':
        return languageCode == 'pt'
            ? 'Quero encontrar lugares seguros para comer e registrar minhas experiências.'
            : languageCode == 'es'
                ? 'Quiero encontrar lugares seguros para comer y registrar mis experiencias.'
                : 'I want to find safe places to eat and record my experiences.';
      case 'businessLoginTitle':
        return languageCode == 'pt'
            ? 'Sou empresa'
            : languageCode == 'es'
                ? 'Soy empresa'
                : 'I am a business';
      case 'businessLoginSubtitle':
        return languageCode == 'pt'
            ? 'Quero divulgar meu negócio, gerenciar avaliações e aparecer para mais clientes.'
            : languageCode == 'es'
                ? 'Quiero divulgar mi negocio, gestionar reseñas y aparecer para más clientes.'
                : 'I want to promote my business, manage reviews and reach more customers.';
      case 'email':
        return languageCode == 'pt'
            ? 'Email'
            : languageCode == 'es'
                ? 'Email.'
                : 'Email';
      case 'loginEnterValidEmailForReset':
        return languageCode == 'pt'
            ? 'Informe um email válido para recuperar sua senha.'
            : languageCode == 'es'
                ? 'Ingresa un correo válido para recuperar tu contraseña.'
                : 'Enter a valid email to recover your password.';
      case 'socialLoginComingSoon':
        return languageCode == 'pt'
            ? 'Login social adicional em breve.'
            : languageCode == 'es'
                ? 'Inicio de sesión social adicional pronto.'
                : 'Additional social login coming soon.';
      case 'welcomeBack':
        return languageCode == 'pt'
            ? 'Bem-vindo de volta'
            : languageCode == 'es'
                ? 'Bienvenido de nuevo'
                : 'Welcome back';
      case 'profileImpactPrefix':
        return languageCode == 'pt'
            ? 'Você já publicou'
            : languageCode == 'es'
                ? 'Ya publicaste'
                : 'You have already published';
      case 'profileImpactSuffix':
        return languageCode == 'pt'
            ? 'avaliações focadas em segurança alimentar.'
            : languageCode == 'es'
                ? 'reseñas enfocadas en seguridad alimentaria.'
                : 'reviews focused on food safety.';
      case 'profileImpactEmpty':
        return languageCode == 'pt'
            ? 'Comece a deixar avaliações para ajudar outras pessoas a comer com segurança.'
            : languageCode == 'es'
                ? 'Empieza a dejar reseñas para ayudar a otras personas a comer con seguridad.'
                : 'Start leaving reviews to help other people eat safely.';

      // Check-in
      case 'checkIn':
        return languageCode == 'pt' ? 'Check-in' : languageCode == 'es' ? 'Registro' : 'Check-in';
      case 'onlyUsersCanCheckIn':
        return languageCode == 'pt' ? 'Apenas usuários podem fazer check-in' : languageCode == 'es' ? 'Solo los usuarios pueden hacer registro' : 'Only users can check-in';
      case 'checkInSuccess':
        return languageCode == 'pt' ? 'Check-in realizado! +10 pontos 🎉' : languageCode == 'es' ? '¡Registro realizado! +10 puntos 🎉' : 'Check-in completed! +10 points 🎉';
      case 'checkInError':
        return languageCode == 'pt' ? 'Erro ao fazer check-in:' : languageCode == 'es' ? 'Error al hacer registro:' : 'Error checking in:';
      case 'checkIns':
        return languageCode == 'pt' ? 'Check-ins' : languageCode == 'es' ? 'Registros' : 'Check-ins';
      case 'checkInHistory':
        return languageCode == 'pt' ? 'Histórico de Check-ins' : languageCode == 'es' ? 'Historial de Registros' : 'Check-in History';
      case 'checkInsCompleted':
        return languageCode == 'pt' ? 'check-ins realizados' : languageCode == 'es' ? 'registros realizados' : 'check-ins completed';

      // Coupons
      case 'coupons':
        return languageCode == 'pt' ? 'Cupons' : languageCode == 'es' ? 'Cupones' : 'Coupons';
      case 'myCoupons':
        return languageCode == 'pt' ? 'Meus Cupons' : languageCode == 'es' ? 'Mis Cupones' : 'My Coupons';
      case 'redeemCoupon':
        return languageCode == 'pt' ? 'Resgatar Cupom' : languageCode == 'es' ? 'Canjear Cupón' : 'Redeem Coupon';
      case 'redeemCoupons':
        return languageCode == 'pt' ? 'Resgatar Cupons' : languageCode == 'es' ? 'Canjear Cupones' : 'Redeem Coupons';
      case 'redeemCouponConfirm':
        return languageCode == 'pt' ? 'Deseja resgatar' : languageCode == 'es' ? '¿Deseas canjear' : 'Do you want to redeem';
      case 'redeemCouponConfirmPoints':
        return languageCode == 'pt' ? 'por' : languageCode == 'es' ? 'por' : 'for';
      case 'redeemCouponConfirmPointsEnd':
        return languageCode == 'pt' ? 'pontos?' : languageCode == 'es' ? 'puntos?' : 'points?';
      case 'yourPoints':
        return languageCode == 'pt' ? 'Seus pontos:' : languageCode == 'es' ? 'Tus puntos:' : 'Your points:';
      case 'enterCouponCode':
        return languageCode == 'pt' ? 'Digite o código do cupom:' : languageCode == 'es' ? 'Ingresa el código del cupón:' : 'Enter coupon code:';
      case 'couponCode':
        return languageCode == 'pt' ? 'Código do Cupom' : languageCode == 'es' ? 'Código del Cupón' : 'Coupon Code';
      case 'couponCodeExample':
        return languageCode == 'pt' ? 'Ex: CUPOM123' : languageCode == 'es' ? 'Ej: CUPON123' : 'Ex: COUPON123';
      case 'couponCodeInfo':
        return languageCode == 'pt' ? 'Os códigos de cupons são fornecidos pelos estabelecimentos ou através de campanhas especiais.' : languageCode == 'es' ? 'Los códigos de cupones son proporcionados por los establecimientos o a través de campañas especiales.' : 'Coupon codes are provided by establishments or through special campaigns.';
      case 'active':
        return languageCode == 'pt' ? 'Ativos' : languageCode == 'es' ? 'Activos' : 'Active';
      case 'expired':
        return languageCode == 'pt' ? 'Expirados' : languageCode == 'es' ? 'Expirados' : 'Expired';
      case 'all':
        return languageCode == 'pt' ? 'Todos' : languageCode == 'es' ? 'Todos' : 'All';
      case 'noCouponsActive':
        return languageCode == 'pt' ? 'Nenhum cupom ativo' : languageCode == 'es' ? 'Ningún cupón activo' : 'No active coupons';
      case 'noCouponsExpired':
        return languageCode == 'pt' ? 'Nenhum cupom expirado' : languageCode == 'es' ? 'Ningún cupón expirado' : 'No expired coupons';
      case 'noCoupons':
        return languageCode == 'pt' ? 'Nenhum cupom' : languageCode == 'es' ? 'Ningún cupón' : 'No coupons';
      case 'redeemCouponsWithPoints':
        return languageCode == 'pt' ? 'Resgate cupons com seus pontos!' : languageCode == 'es' ? '¡Canjea cupones con tus puntos!' : 'Redeem coupons with your points!';
      case 'discount':
        return languageCode == 'pt' ? 'de desconto' : languageCode == 'es' ? 'de descuento' : 'discount';
      case 'at':
        return languageCode == 'pt' ? 'Em:' : languageCode == 'es' ? 'En:' : 'At:';
      case 'usedOn':
        return languageCode == 'pt' ? 'Usado em' : languageCode == 'es' ? 'Usado en' : 'Used on';
      case 'expiredOn':
        return languageCode == 'pt' ? 'Expirado em' : languageCode == 'es' ? 'Expirado en' : 'Expired on';
      case 'validUntil':
        return languageCode == 'pt' ? 'Válido até' : languageCode == 'es' ? 'Válido hasta' : 'Valid until';
      case 'insufficientPoints':
        return languageCode == 'pt' ? 'Pontos insuficientes! Você precisa de' : languageCode == 'es' ? '¡Puntos insuficientes! Necesitas' : 'Insufficient points! You need';
      case 'pointsRequired':
        return languageCode == 'pt' ? 'pontos.' : languageCode == 'es' ? 'puntos.' : 'points.';
      case 'couponRedeemedSuccess':
        return languageCode == 'pt' ? 'Cupom resgatado com sucesso! 🎉' : languageCode == 'es' ? '¡Cupón canjeado con éxito! 🎉' : 'Coupon redeemed successfully! 🎉';
      case 'couponRedeemError':
        return languageCode == 'pt' ? 'Erro ao resgatar cupom:' : languageCode == 'es' ? 'Error al canjear cupón:' : 'Error redeeming coupon:';
      case 'loadCouponsError':
        return languageCode == 'pt' ? 'Erro ao carregar cupons:' : languageCode == 'es' ? 'Error al cargar cupones:' : 'Error loading coupons:';
      case 'pleaseEnterCouponCode':
        return languageCode == 'pt' ? 'Por favor, digite o código do cupom' : languageCode == 'es' ? 'Por favor, ingresa el código del cupón' : 'Please enter coupon code';
      case 'invalidCouponCode':
        return languageCode == 'pt' ? 'Código de cupom inválido ou expirado' : languageCode == 'es' ? 'Código de cupón inválido o expirado' : 'Invalid or expired coupon code';
      case 'activeCoupons':
        return languageCode == 'pt' ? 'cupons ativos' : languageCode == 'es' ? 'cupones activos' : 'active coupons';

      // User Profile
      case 'onlyUsersCanAccessProfile':
        return languageCode == 'pt' ? 'Apenas usuários podem acessar este perfil' : languageCode == 'es' ? 'Solo los usuarios pueden acceder a este perfil' : 'Only users can access this profile';
      case 'shareAchievements':
        return languageCode == 'pt' ? 'Compartilhar conquistas' : languageCode == 'es' ? 'Compartir logros' : 'Share achievements';
      case 'premiumAccountActive':
        return languageCode == 'pt' ? 'Conta Premium Ativa' : languageCode == 'es' ? 'Cuenta Premium Activa' : 'Premium Account Active';
      case 'expiresIn':
        return languageCode == 'pt' ? 'Expira em' : languageCode == 'es' ? 'Expira en' : 'Expires in';
      case 'premiumPlanTab':
        return languageCode == 'pt' ? 'Plano' : languageCode == 'es' ? 'Plan Premium' : 'Premium Plan';
      case 'premiumStatusActive':
        return languageCode == 'pt' ? 'Status: Premium ativo' : languageCode == 'es' ? 'Estado: Premium activo' : 'Status: Premium active';
      case 'premiumStatusInactive':
        return languageCode == 'pt' ? 'Status: Você ainda não é Premium' : languageCode == 'es' ? 'Estado: Todavía no eres Premium' : 'Status: You are not Premium yet';
      case 'premiumTrialNote':
        return languageCode == 'pt'
            ? 'Durante o piloto, os primeiros 100 usuários ganham 30 dias de Premium gratuitamente ao criar a conta.'
            : languageCode == 'es'
                ? 'Durante el piloto, los primeros 100 usuarios reciben 30 días de Premium gratis al crear la cuenta.'
                : 'During the pilot, the first 100 users get 30 days of Premium for free when creating their account.';
      case 'premiumDaysRemaining':
        return languageCode == 'pt'
            ? 'dias de Premium restantes'
            : languageCode == 'es'
                ? 'días de Premium restantes'
                : 'Premium days remaining';
      case 'seePlanDetails':
        return languageCode == 'pt'
            ? 'Ver detalhes do plano'
            : languageCode == 'es'
                ? 'Ver detalles del plan'
                : 'See plan details';
      case 'premiumTrialHomeTitle':
        return languageCode == 'pt'
            ? 'Período Premium de teste'
            : languageCode == 'es'
                ? 'Periodo de prueba Premium'
                : 'Premium trial period';
      case 'premiumTrialHomeDescription':
        return languageCode == 'pt'
            ? 'Você está com acesso Premium liberado. Durante o piloto, os primeiros 100 usuários ganham 30 dias gratuitos.'
            : languageCode == 'es'
                ? 'Tienes acceso Premium activado. Durante el piloto, los primeros 100 usuarios reciben 30 días gratuitos.'
                : 'Your Premium access is active. During the pilot, the first 100 users get 30 days for free.';
      case 'becomePremium':
        return languageCode == 'pt' ? 'Torne-se Premium' : languageCode == 'es' ? 'Conviértete en Premium' : 'Become Premium';
      case 'premiumBenefits':
        return languageCode == 'pt' ? 'Acesso antecipado, filtros avançados e muito mais!' : languageCode == 'es' ? '¡Acceso anticipado, filtros avanzados y mucho más!' : 'Early access, advanced filters and much more!';
      case 'becomePremiumInfo':
        return languageCode == 'pt' ? 'Para tornar-se Premium, entre em contato com o suporte ou use o painel administrativo.' : languageCode == 'es' ? 'Para convertirte en Premium, contacta con soporte o usa el panel administrativo.' : 'To become Premium, contact support or use the admin panel.';
      case 'premium':
        return languageCode == 'pt' ? 'Premium' : languageCode == 'es' ? 'Premium' : 'Premium';
      case 'seal':
        return languageCode == 'pt' ? 'Selo' : languageCode == 'es' ? 'Sello' : 'Seal';
      case 'userSealBronzeLabel':
        return languageCode == 'pt' ? 'Bronze' : languageCode == 'es' ? 'Bronce' : 'Bronze';
      case 'userSealSilverLabel':
        return languageCode == 'pt' ? 'Prata' : languageCode == 'es' ? 'Plata' : 'Silver';
      case 'userSealGoldLabel':
        return languageCode == 'pt' ? 'Ouro' : languageCode == 'es' ? 'Oro' : 'Gold';
      case 'userSealBronzeDescription':
        return languageCode == 'pt' ? 'Iniciante' : languageCode == 'es' ? 'Principiante' : 'Beginner';
      case 'userSealSilverDescription':
        return languageCode == 'pt' ? 'Colaborador' : languageCode == 'es' ? 'Colaborador' : 'Contributor';
      case 'userSealGoldDescription':
        return languageCode == 'pt' ? 'Embaixador Prato Seguro' : languageCode == 'es' ? 'Embajador Prato Seguro' : 'Prato Seguro Ambassador';
      case 'points':
        return languageCode == 'pt' ? 'Pontos' : languageCode == 'es' ? 'Puntos' : 'Points';
      case 'pointsToRedeemPremium':
        return languageCode == 'pt' ? 'pontos para resgatar 1 mês Premium' : languageCode == 'es' ? 'puntos para canjear 1 mes Premium' : 'points to redeem 1 month Premium';
      case 'quickActions':
        return languageCode == 'pt' ? 'Ações Rápidas' : languageCode == 'es' ? 'Acciones Rápidas' : 'Quick Actions';
      case 'history':
        return languageCode == 'pt' ? 'Histórico' : languageCode == 'es' ? 'Historial' : 'History';
      case 'referNewPlace':
        return languageCode == 'pt' ? 'Indicar Novo Local' : languageCode == 'es' ? 'Indicar Nuevo Lugar' : 'Refer New Place';
      case 'statistics':
        return languageCode == 'pt' ? 'Estatísticas' : languageCode == 'es' ? 'Estadísticas' : 'Statistics';
      case 'reviews':
        return languageCode == 'pt' ? 'Avaliações' : languageCode == 'es' ? 'Reseñas' : 'Reviews';
      case 'referrals':
        return languageCode == 'pt' ? 'Indicações' : languageCode == 'es' ? 'Referencias' : 'Referrals';
      case 'seeAll':
        return languageCode == 'pt' ? 'Ver todos' : languageCode == 'es' ? 'Ver todos' : 'See all';
      case 'registerTrail':
        return languageCode == 'pt' ? 'Registrar Trilha' : languageCode == 'es' ? 'Registrar Ruta' : 'Log Trail';
      case 'registerTrailSubtitle':
        return languageCode == 'pt' ? 'Ganhe pontos mapeando locais' : languageCode == 'es' ? 'Gana puntos mapeando lugares' : 'Earn points by mapping places';
      case 'leaderboardSubtitle':
        return languageCode == 'pt' ? 'Veja o ranking da comunidade' : languageCode == 'es' ? 'Mira el ranking de la comunidad' : 'See the community leaderboard';
      case 'userSearchTitle':
        return languageCode == 'pt' ? 'Buscar usuários' : languageCode == 'es' ? 'Buscar usuarios' : 'Search users';
      case 'userSearchSubtitle':
        return languageCode == 'pt' ? 'Encontre perfis da comunidade' : languageCode == 'es' ? 'Encuentra perfiles de la comunidad' : 'Find community profiles';
      case 'userSearchHint':
        return languageCode == 'pt' ? 'Buscar por nome ou email...' : languageCode == 'es' ? 'Buscar por nombre o correo...' : 'Search by name or email...';
      case 'userSearchEmpty':
        return languageCode == 'pt' ? 'Nenhum usuário encontrado' : languageCode == 'es' ? 'Ningún usuario encontrado' : 'No users found';
      case 'travelMode':
        return languageCode == 'pt' ? 'Modo Viagem' : languageCode == 'es' ? 'Modo Viaje' : 'Travel Mode';
      case 'manage':
        return languageCode == 'pt' ? 'Gerenciar' : languageCode == 'es' ? 'Gestionar' : 'Manage';
      case 'downloadRegionData':
        return languageCode == 'pt' ? 'Baixe dados de uma região para usar sem internet' : languageCode == 'es' ? 'Descarga datos de una región para usar sin internet' : 'Download region data to use without internet';
      case 'days':
        return languageCode == 'pt' ? 'dias' : languageCode == 'es' ? 'días' : 'days';
      case 'hours':
        return languageCode == 'pt' ? 'horas' : languageCode == 'es' ? 'horas' : 'hours';
      case 'today':
        return languageCode == 'pt' ? 'Hoje' : languageCode == 'es' ? 'Hoy' : 'Today';
      case 'onboardingTitle1':
        return languageCode == 'pt'
            ? 'Comer fora não precisa ser um risco.'
            : languageCode == 'es'
                ? 'Comer fuera no tiene por qué ser un riesgo.'
                : 'Eating out doesn\'t have to be a risk.';
      case 'onboardingDescription1':
        return languageCode == 'pt'
            ? 'O Prato Seguro conecta você a restaurantes, padarias e locais que respeitam suas restrições alimentares — com segurança, confiança e praticidade.'
            : languageCode == 'es'
                ? 'Prato Seguro te conecta con restaurantes, panaderías y lugares que respetan tus restricciones alimentarias, con seguridad, confianza y practicidad.'
                : 'Prato Seguro connects you to restaurants, bakeries and places that respect your dietary restrictions — with safety, trust and convenience.';
      case 'onboardingTitle2':
        return languageCode == 'pt'
            ? 'Encontre lugares seguros.'
            : languageCode == 'es'
                ? 'Encuentra lugares seguros.'
                : 'Find safe places.';
      case 'onboardingDescription2':
        return languageCode == 'pt'
            ? 'Encontre opções para celíacos, veganos, alérgicos e muito mais, com filtros pensados para quem vive com restrições.'
            : languageCode == 'es'
                ? 'Encuentra opciones para celíacos, veganos, alérgicos y mucho más, con filtros pensados para quienes viven con restricciones.'
                : 'Find options for celiacs, vegans, people with allergies and more, with filters designed for those living with restrictions.';
      case 'onboardingTitle3':
        return languageCode == 'pt'
            ? 'Descubra opções próximas.'
            : languageCode == 'es'
                ? 'Descubre opciones cercanas.'
                : 'Discover nearby options.';
      case 'onboardingDescription3':
        return languageCode == 'pt'
            ? 'Use o mapa, filtros inteligentes e alertas em tempo real para decidir onde comer com mais tranquilidade.'
            : languageCode == 'es'
                ? 'Utiliza el mapa, filtros inteligentes y alertas en tiempo real para decidir dónde comer con más tranquilidad.'
                : 'Use the map, smart filters and real-time alerts to decide where to eat with more peace of mind.';
      case 'onboardingTitle4':
        return languageCode == 'pt'
            ? 'Ganhe pontos, selos e benefícios.'
            : languageCode == 'es'
                ? 'Gana puntos, sellos y beneficios.'
                : 'Earn points, badges and benefits.';
      case 'onboardingDescription4':
        return languageCode == 'pt'
            ? 'Veja avaliações focadas em segurança alimentar, registre suas experiências e desbloqueie recompensas usando o app.'
            : languageCode == 'es'
                ? 'Mira reseñas enfocadas en seguridad alimentaria, registra tus experiencias y desbloquea recompensas usando la app.'
                : 'See reviews focused on food safety, record your experiences and unlock rewards by using the app.';
      case 'onboardingSkip':
        return languageCode == 'pt' ? 'Pular' : languageCode == 'es' ? 'Omitir' : 'Skip';
      case 'onboardingNext':
        return languageCode == 'pt' ? 'Avançar' : languageCode == 'es' ? 'Siguiente' : 'Next';
      case 'onboardingStart':
        return languageCode == 'pt' ? 'Começar' : languageCode == 'es' ? 'Empezar' : 'Start';
      case 'businessOnboardingTitle1':
        return languageCode == 'pt'
            ? 'Bem-vindo ao painel da sua empresa'
            : languageCode == 'es'
                ? 'Bienvenido al panel de tu empresa'
                : 'Welcome to your business dashboard';
      case 'businessOnboardingDescription1':
        return languageCode == 'pt'
            ? 'Aqui você acompanha seus estabelecimentos, avaliações e presença no Prato Seguro.'
            : languageCode == 'es'
                ? 'Aquí acompañas tus establecimientos, reseñas y presencia en Prato Seguro.'
                : 'Here you track your venues, reviews and presence on Prato Seguro.';
      case 'businessOnboardingTitle2':
        return languageCode == 'pt'
            ? 'Dashboard e estatísticas'
            : languageCode == 'es'
                ? 'Panel y estadísticas'
                : 'Dashboard and statistics';
      case 'businessOnboardingDescription2':
        return languageCode == 'pt'
            ? 'Veja quantos estabelecimentos você cadastrou, quais estão abertos e como estão suas avaliações.'
            : languageCode == 'es'
                ? 'Mira cuántos establecimientos registraste, cuáles están abiertos y cómo están tus reseñas.'
                : 'See how many venues you have, which are open and how your reviews are going.';
      case 'businessOnboardingTitle3':
        return languageCode == 'pt'
            ? 'Anúncios e planos para destacar seu negócio'
            : languageCode == 'es'
                ? 'Anuncios y planes para destacar tu negocio'
                : 'Ads and plans to highlight your business';
      case 'businessOnboardingDescription3':
        return languageCode == 'pt'
            ? 'Use os planos e anúncios para aumentar a visibilidade do seu estabelecimento dentro do Prato Seguro.'
            : languageCode == 'es'
                ? 'Utiliza los planes y anuncios para aumentar la visibilidad de tu establecimiento dentro de Prato Seguro.'
                : 'Use plans and ads to increase your venue\'s visibility inside Prato Seguro.';
      case 'appSlogan':
        return languageCode == 'pt'
            ? 'Onde comer com confiança.'
            : languageCode == 'es'
                ? 'Dónde comer con confianza.'
                : 'Where to eat with confidence.';
      // Notifications & Leaderboard
      case 'notifications':
        return languageCode == 'pt' ? 'Notificações' : languageCode == 'es' ? 'Notificaciones' : 'Notifications';
      case 'noNotificationsYet':
        return languageCode == 'pt'
            ? 'Você ainda não recebeu notificações.'
            : languageCode == 'es'
                ? 'Todavía no has recibido notificaciones.'
                : 'You have not received any notifications yet.';
      case 'leaderboardError':
        return languageCode == 'pt'
            ? 'Erro ao carregar ranking. Tente novamente.'
            : languageCode == 'es'
                ? 'Error al cargar el ranking. Inténtalo de nuevo.'
                : 'Error loading leaderboard. Please try again.';
      case 'leaderboardEmpty':
        return languageCode == 'pt'
            ? 'Ainda não há avaliadores suficientes para o ranking.'
            : languageCode == 'es'
                ? 'Todavía no hay suficientes reseñadores para el ranking.'
                : 'There are not enough reviewers for the leaderboard yet.';
      case 'topReviewers':
        return languageCode == 'pt' ? 'Top Avaliadores' : languageCode == 'es' ? 'Top Reseñadores' : 'Top Reviewers';

      // Followers / Following
      case 'followers':
        return languageCode == 'pt' ? 'seguidores' : languageCode == 'es' ? 'seguidores' : 'followers';
      case 'following':
        return languageCode == 'pt' ? 'seguidos' : languageCode == 'es' ? 'seguidos' : 'following';
      case 'follow':
        return languageCode == 'pt' ? 'Seguir' : languageCode == 'es' ? 'Seguir' : 'Follow';
      case 'followingVerb':
        return languageCode == 'pt' ? 'Seguindo' : languageCode == 'es' ? 'Siguiendo' : 'Following';
      case 'noFollowersYet':
        return languageCode == 'pt'
            ? 'Você ainda não tem seguidores.'
            : languageCode == 'es'
                ? 'Todavía no tienes seguidores.'
                : 'You do not have any followers yet.';
      case 'noFollowingYet':
        return languageCode == 'pt'
            ? 'Você ainda não está seguindo ninguém.'
            : languageCode == 'es'
                ? 'Todavía no sigues a nadie.'
                : 'You are not following anyone yet.';

      // Diet Preferences
      case 'dietPreferencesTitle':
        return languageCode == 'pt' ? 'Preferências de comida segura' : languageCode == 'es' ? 'Preferencias de comida segura' : 'Safe food preferences';
      case 'dietPreferencesEmpty':
        return languageCode == 'pt'
            ? 'Você ainda não definiu suas preferências. Elas ajudam a encontrar lugares que atendem às suas restrições.'
            : languageCode == 'es'
                ? 'Aún no definiste tus preferencias. Ayudan a encontrar lugares que respetan tus restricciones.'
                : 'You have not set your preferences yet. They help find places that match your restrictions.';
      case 'dietPreferencesNudge':
        return languageCode == 'pt'
            ? 'Defina suas preferências de comida segura para receber resultados e alertas mais relevantes.'
            : languageCode == 'es'
                ? 'Define tus preferencias de comida segura para recibir resultados y alertas más relevantes.'
                : 'Set your safe food preferences to get more relevant results and alerts.';
      case 'dietaryDiabetic':
        return languageCode == 'pt' ? 'Adequado para diabéticos' : languageCode == 'es' ? 'Apto para personas con diabetes' : 'Suitable for people with diabetes';
      case 'save':
        return languageCode == 'pt' ? 'Salvar' : languageCode == 'es' ? 'Guardar' : 'Save';

      // Mascot
      case 'mascotTitleStart':
        return languageCode == 'pt' ? 'Comece sua jornada de comida segura' : languageCode == 'es' ? 'Comienza tu jornada de comida segura' : 'Start your safe food journey';
      case 'mascotMessageStart':
        return languageCode == 'pt'
            ? 'Faça seus primeiros check-ins e avaliações para o mascote entender o seu jeito de comer.'
            : languageCode == 'es'
                ? 'Haz tus primeros registros y reseñas para que la mascota entienda tu forma de comer.'
                : 'Do your first check-ins and reviews so the mascot can learn your way of eating.';
      case 'mascotTitleBronze':
        return languageCode == 'pt' ? 'Você já está na trilha certa' : languageCode == 'es' ? 'Ya estás en el camino correcto' : 'You are already on the right track';
      case 'mascotMessageBronze':
        return languageCode == 'pt'
            ? 'Com seus check-ins e avaliações, você já ajuda outras pessoas a comer com mais segurança.'
            : languageCode == 'es'
                ? 'Con tus registros y reseñas ya ayudas a otras personas a comer con más seguridad.'
                : 'With your check-ins and reviews, you are already helping others eat more safely.';
      case 'mascotTitleSilver':
        return languageCode == 'pt' ? 'Você é referência na comunidade' : languageCode == 'es' ? 'Eres referencia en la comunidad' : 'You are a community reference';
      case 'mascotMessageSilver':
        return languageCode == 'pt'
            ? 'Suas avaliações e indicações estão guiando muita gente a lugares mais seguros.'
            : languageCode == 'es'
                ? 'Tus reseñas e indicaciones están guiando a muchas personas a lugares más seguros.'
                : 'Your reviews and referrals are guiding many people to safer places.';
      case 'mascotTitleGold':
        return languageCode == 'pt' ? 'Guardião do Prato Seguro' : languageCode == 'es' ? 'Guardián de Prato Seguro' : 'Prato Seguro guardian';
      case 'mascotMessageGold':
        return languageCode == 'pt'
            ? 'Você é um dos perfis que mais protege a comunidade com avaliações focadas em segurança.'
            : languageCode == 'es'
                ? 'Eres uno de los perfiles que más protege a la comunidad con reseñas enfocadas en seguridad.'
                : 'You are one of the profiles that most protects the community with safety-focused reviews.';
      case 'mascotTitleReferralHero':
        return languageCode == 'pt' ? 'Herói das indicações' : languageCode == 'es' ? 'Héroe de las indicaciones' : 'Referral hero';
      case 'mascotMessageReferralHero':
        return languageCode == 'pt'
            ? 'Suas indicações estão abrindo novos caminhos de comida segura para a comunidade.'
            : languageCode == 'es'
                ? 'Tus indicaciones están abriendo nuevos caminos de comida segura para la comunidad.'
                : 'Your referrals are opening new safe food paths for the community.';
      case 'mascotTitleReferralChampion':
        return languageCode == 'pt' ? 'Campeão de indicações' : languageCode == 'es' ? 'Campeón de indicaciones' : 'Referral champion';
      case 'mascotMessageReferralChampion':
        return languageCode == 'pt'
            ? 'Você já indicou vários locais seguros. O mapa do Prato Seguro existe graças a pessoas como você.'
            : languageCode == 'es'
                ? 'Ya indicaste varios lugares seguros. El mapa de Prato Seguro existe gracias a personas como tú.'
                : 'You have already referred several safe places. The Prato Seguro map exists thanks to people like you.';

      // Badges & Misc
      case 'communityBadgeConnector':
        return languageCode == 'pt' ? 'Conector da comunidade' : languageCode == 'es' ? 'Conector de la comunidad' : 'Community connector';
      case 'communityBadgeInfluencer':
        return languageCode == 'pt' ? 'Influencer da comunidade' : languageCode == 'es' ? 'Influencer de la comunidad' : 'Community influencer';
      case 'communityBadgeAmbassador':
        return languageCode == 'pt' ? 'Embaixador da comunidade' : languageCode == 'es' ? 'Embajador de la comunidad' : 'Community ambassador';
      case 'sealProgressTowards':
        return languageCode == 'pt' ? 'de progresso para o próximo selo' : languageCode == 'es' ? 'de progreso hacia la próxima medalla' : 'progress towards the next badge';
      case 'trailHistoryTitle':
        return languageCode == 'pt' ? 'Últimos check-ins' : languageCode == 'es' ? 'Últimos registros' : 'Latest check-ins';
      case 'trailHistoryEmpty':
        return languageCode == 'pt' ? 'Este usuário ainda não registrou trilhas.' : languageCode == 'es' ? 'Este usuario aún no registró rutas.' : 'This user has not registered any trails yet.';

      // WhatsApp Group
      case 'homeWhatsAppGroupTitle':
        return languageCode == 'pt'
            ? 'Grupo oficial no WhatsApp'
            : languageCode == 'es'
                ? 'Grupo oficial en WhatsApp'
                : 'Official WhatsApp group';
      case 'homeWhatsAppGroupDescription':
        return languageCode == 'pt'
            ? 'Faça parte do grupo oficial Prato Seguro no WhatsApp e fique por dentro das novidades.'
            : languageCode == 'es'
                ? 'Forma parte del grupo oficial de Prato Seguro en WhatsApp y mantente al tanto de las novedades.'
                : 'Join the official Prato Seguro WhatsApp group and stay up to date with the news.';
      case 'homeWhatsAppGroupButton':
        return languageCode == 'pt'
            ? 'Entrar no grupo'
            : languageCode == 'es'
                ? 'Entrar al grupo'
                : 'Join group';
      case 'homeWhatsAppGroupOpenError':
        return languageCode == 'pt'
            ? 'Não foi possível abrir o WhatsApp. Tente novamente.'
            : languageCode == 'es'
                ? 'No fue posible abrir WhatsApp. Inténtalo de nuevo.'
                : 'Could not open WhatsApp. Please try again.';

      // Settings & Profile
      case 'settings':
        return languageCode == 'pt' ? 'Ajustes' : languageCode == 'es' ? 'Configuración' : 'Settings';
      case 'profilePhotoUpdated':
        return languageCode == 'pt'
            ? 'Foto de perfil atualizada!'
            : languageCode == 'es'
                ? 'Foto de perfil actualizada.'
                : 'Profile photo updated!';
      case 'coverPhotoUpdated':
        return languageCode == 'pt'
            ? 'Capa atualizada!'
            : languageCode == 'es'
                ? 'Portada actualizada.'
                : 'Cover photo updated!';
      case 'editProfile':
        return languageCode == 'pt' ? 'Editar Perfil' : languageCode == 'es' ? 'Editar Perfil' : 'Edit Profile';
      case 'referEstablishment':
        return languageCode == 'pt' ? 'Indicar Estabelecimento' : languageCode == 'es' ? 'Indicar Establecimiento' : 'Refer Establishment';
      case 'helpCommunity':
        return languageCode == 'pt' ? 'Ajude a comunidade a crescer' : languageCode == 'es' ? 'Ayuda a la comunidad a crecer' : 'Help the community grow';
      case 'leaderboard':
        return languageCode == 'pt' ? 'Ranking' : languageCode == 'es' ? 'Clasificación' : 'Leaderboard';
      case 'changeCoverPhoto':
        return languageCode == 'pt' ? 'Alterar Capa' : languageCode == 'es' ? 'Cambiar Portada' : 'Change Cover';
      case 'trailMap':
        return languageCode == 'pt' ? 'Trilha' : languageCode == 'es' ? 'Mapa de la Ruta' : 'Trail Map';
      case 'viewTrail':
        return languageCode == 'pt' ? 'Ver Trilha' : languageCode == 'es' ? 'Ver Ruta' : 'View Trail';

      default:
        debugPrint('Missing translation for key: ' + key + ' (lang: ' + languageCode + ')');
        return key;
    }
  }
}
