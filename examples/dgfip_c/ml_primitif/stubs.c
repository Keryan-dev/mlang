
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#define CAML_NAME_SPACE
#include "caml/version.h"
#include "caml/mlvalues.h"
#include "caml/memory.h"
#include "caml/alloc.h"
#include "caml/fail.h"

#include "calc/annee.h"
#include "calc/conf.h"
#include "calc/irdata.h"
#include "calc/const.h"
#include "calc/var.h"
#include "calc/enchain.h"

#if OCAML_VERSION < 41200

#define Val_none Val_int(0)

CAMLexport value caml_alloc_some(value v)
{
  CAMLparam1(v);
  value some = caml_alloc_small(1, 0);
  Field(some, 0) = v;
  CAMLreturn(some);
}

#endif

// Non exportés dans headers standards
extern T_desc_penalite desc_penalite[];
extern T_desc_debug desc_debug01[];

typedef void (*ench_fun)(T_irdata *);

typedef struct ench_t {
  char *name;
  ench_fun function;
} ench_t;

static ench_t enchaineurs[] = {
  { "calcul_primitif", calcul_primitif },
  { "calcul_primitif_isf", calcul_primitif_isf },
  { "calcul_primitif_taux", calcul_primitif_taux },
  { "calcul_correctif", calcul_correctif },

  { "sauve_base_initial", sauve_base_initial },
  { "sauve_base_1728", sauve_base_1728 },
  { "sauve_base_anterieure_cor", sauve_base_anterieure_cor },
  { "sauve_base_premier", sauve_base_premier },

  { "sauve_base_tl_init", sauve_base_tl_init },
  { "sauve_base_tl", sauve_base_tl },
  { "sauve_base_tl_rect", sauve_base_tl_rect },
  { "sauve_base_tlnunv", sauve_base_tlnunv },

  { "sauve_base_inr_r9901", sauve_base_inr_r9901 },
  { "sauve_base_inr_cimr99", sauve_base_inr_cimr99 },
  { "sauve_base_HR", sauve_base_HR },
  { "sauve_base_inr_cimr07", sauve_base_inr_cimr07 },
  { "sauve_base_inr_tlcimr07", sauve_base_inr_tlcimr07 },
  { "sauve_base_inr_cimr24", sauve_base_inr_cimr24 },
  { "sauve_base_inr_tlcimr24", sauve_base_inr_tlcimr24 },
  { "sauve_base_inr_ref", sauve_base_inr_ref },
  { "sauve_base_inr_ntl", sauve_base_inr_ntl },
  { "sauve_base_abat98", sauve_base_abat98 },
  { "sauve_base_inr_ntl", sauve_base_inr_ntl },
  { "sauve_base_inr_intertl", sauve_base_inr_intertl },
  { "sauve_base_inr_ntl22", sauve_base_inr_ntl22 },
  { "sauve_base_inr", sauve_base_inr },
  { "sauve_base_inr_ntl24", sauve_base_inr_ntl24 },
  { "sauve_base_inr_tl", sauve_base_inr_tl },
  { "sauve_base_abat99", sauve_base_abat99 },
  { "sauve_base_inr_tl", sauve_base_inr_tl },
  { "sauve_base_inr_tl22", sauve_base_inr_tl22 },
  { "sauve_base_inr_tl24", sauve_base_inr_tl24 },
  { "sauve_base_inr_inter22", sauve_base_inr_inter22 },

  { "sauve_base_majo", sauve_base_majo },
  { "sauve_base_anterieure", sauve_base_anterieure },
  { "sauve_base_stratemajo", sauve_base_stratemajo },

  { "ENCH_TL", ENCH_TL }
};

extern struct S_discord * verif_calcul_primitive(T_irdata *irdata);
extern struct S_discord * verif_calcul_primitive_isf(T_irdata *irdata);
extern struct S_discord * verif_calcul_corrective(T_irdata *irdata);
extern struct S_discord * verif_saisie_cohe_primitive(T_irdata *irdata);
extern struct S_discord * verif_saisie_cohe_primitive_isf(T_irdata *irdata, int appel);
extern struct S_discord * verif_saisie_cohe_corrective(T_irdata *irdata);
extern struct S_discord * verif_cohe_horizontale(T_irdata *irdata);

struct S_discord * verif_saisie_cohe_primitive_isf_stub(T_irdata *irdata)
{
  return verif_saisie_cohe_primitive_isf(irdata, 0);
}

typedef struct S_discord * (*verif_fun)(T_irdata *);

typedef struct verif_t {
  char *name;
  verif_fun function;
} verif_t;

static verif_t verifications[] = {
  { "verif_calcul_primitive", verif_calcul_primitive },
  { "verif_calcul_primitive_isf",  verif_calcul_primitive_isf },
  { "verif_calcul_corrective", verif_calcul_corrective },
  { "verif_saisie_cohe_primitive", verif_saisie_cohe_primitive },
  { "verif_saisie_cohe_primitive_isf", verif_saisie_cohe_primitive_isf_stub },
  { "verif_saisie_cohe_corrective", verif_saisie_cohe_corrective },
  { "verif_cohe_horizontale", verif_cohe_horizontale },
};

typedef enum genre_t {
  G_SAISIE = 1,
  G_CALCULEE = 2,
  G_BASE = 3,
} genre_t;

typedef enum domaine_t {
  D_INDEFINI = -1,
  D_CONTEXTE = 1,
  D_FAMILLE = 2,
  D_REVENU = 3,
  D_REVENU_CORR = 4,
  D_VARIATION = 5,
  D_PENALITE = 6,
} domaine_t;

typedef enum type_t {
  T_REEL = 1,
  T_BOOLEEN = 2,
  T_DATE = 3,
} type_t;

typedef enum nature_t {
  N_INDEFINIE = -1,
  N_REVENU = 1,
  N_CHARGE = 2,
} nature_t;

typedef struct var_t {
  char *code;
  char *alias;
  genre_t genre;
  domaine_t domaine;
  type_t type;
  nature_t nature;
  int classe;
  int cat_tl;
  int cot_soc;
  bool ind_abat;
  int rap_cat;
  int sanction;
  int cat_1731b;
  int indice_tab;
  bool acompte;
  int avfisc;
  bool restituee;
  T_desc_var *desc;
} var_t;

static var_t var[TAILLE_TOTALE] = { NULL };

typedef struct var_entry_t {
  const char *code; // including alias
  var_t *var;
} var_entry_t;

static var_entry_t * var_index = NULL;
static size_t var_index_entries = 0;
static size_t var_index_size = 0;

static bool var_chargees = false;

static T_irdata *tgv = NULL;

static genre_t convert_genre(int indice)
{
  switch (indice & EST_MASQUE) {
    case EST_SAISIE: return G_SAISIE;
    case EST_CALCULEE: return G_CALCULEE;
    case EST_BASE: return G_BASE;
    default:
      fprintf(stderr, "Genre %8X invalide\n", indice & EST_MASQUE);
      exit(1);
      return -1;
  }
}

static type_t convert_type(long type_donnee)
{
  switch (type_donnee) {
    case BOOLEEN: return T_BOOLEEN;
    case ENTIER: return T_REEL; // T_ENTIER; TODO
    case REEL: return T_REEL;
    //case REEL1: return T_REEL;
    //case REEL2: return T_REEL;
    //case REEL3: return T_REEL;
    case DATE_JJMMAAAA: return T_DATE;
    case DATE_MMAAAA: return T_DATE;
    case DATE_AAAA: return T_DATE;
    case DATE_JJMM: return T_DATE;
    case DATE_MM: return T_DATE;
    default:
      fprintf(stderr, "Type %8lX invalide\n", type_donnee);
      exit(1);
      return -1;
  }
}

static nature_t convert_nature(int nat_code)
{
  switch (nat_code) {
    case -1: return N_INDEFINIE;
    case 0: return N_REVENU;
    case 1: return N_CHARGE;
    default:
      fprintf(stderr, "Code nature %d invalide\n", nat_code);
      exit(1);
      return -1;
  }
}

static void add_var_to_index(const char *code, var_t *var)
{
  if ((code == NULL) || (var == NULL)) {
    fprintf(stderr, "Invalid argument to add_var_to_index");
    exit(1);
  }
  if (var_index == NULL) {
    var_index_entries = 0;
    var_index_size = 1024;
    var_index = calloc(var_index_size, sizeof(var_entry_t));
  } else {
    if (var_index_entries >= var_index_size) {
      var_index_size += var_index_size / 4;
      var_index = realloc(var_index, var_index_size * sizeof(var_entry_t));
    }
  }
  var_index[var_index_entries].code = code;
  var_index[var_index_entries].var = var;
  var_index_entries++;
}

static void sort_index_aux(int first, int last)
{
   int i, j, pivot;
   var_entry_t temp;
   if (first < last) {
     pivot = first;
     i = first;
     j = last;
     while (i < j) {
       while (strcmp(var_index[i].code, var_index[pivot].code) <= 0 && i < last)
         i++;
       while (strcmp(var_index[j].code, var_index[pivot].code) > 0)
         j--;
       if (i < j) {
         temp = var_index[i];
         var_index[i] = var_index[j];
         var_index[j] = temp;
       }
     }
     temp = var_index[pivot];
     var_index[pivot] = var_index[j];
     var_index[j] = temp;
     sort_index_aux(first, j - 1);
     sort_index_aux(j + 1, last);
   }
}

static void sort_index(void)
{
  sort_index_aux(0, var_index_entries - 1);
}

static void init_var_dict(void)
{
  if (var_chargees == true) {
    return;
  }
  var_chargees = true;

  //printf("Chargement des variables contexte\n");
  for (size_t i = 0; i < NB_CONTEXTE; ++i) {
    size_t id = desc_contexte[i].indice & INDICE_VAL;
    if (var[id].desc != NULL) {
      fprintf(stderr,
              "Variable saisie (contexte) à l'indice %ld existe déjà (%s/%s)\n",
              id, var[id].code, desc_contexte[i].nom);
      exit(1);
    }
    var[id].code = NULL;
    var[id].alias = desc_contexte[i].nom;
    var[id].genre = G_SAISIE;
    var[id].domaine = D_CONTEXTE;
    var[id].type = convert_type(desc_contexte[i].type_donnee);
    var[id].nature = convert_nature(desc_contexte[i].modcat); // n'existe pas pour ce domaine
    var[id].classe = desc_contexte[i].classe;
    var[id].cat_tl = desc_contexte[i].categorie_TL;
    var[id].cot_soc = -1;
    var[id].ind_abat = false;
    var[id].rap_cat = -1;
    var[id].sanction = -1;
    var[id].cat_1731b = -1;
    var[id].indice_tab = -1;
    var[id].acompte = false;
    var[id].avfisc = -1;
    var[id].restituee = false;
    var[id].desc = (T_desc_var *)&desc_contexte[i];
    add_var_to_index(var[id].alias, &var[id]);
  }

  //printf("Chargement des variables famille\n");
  for (size_t i = 0; i < NB_FAMILLE; ++i) {
    size_t id = desc_famille[i].indice & INDICE_VAL;
    if (var[id].desc != NULL) {
      fprintf(stderr,
              "Variable saisie (famille) à l'indice %ld existe déjà (%s/%s)\n",
              id, var[id].code, desc_famille[i].nom);
      exit(1);
    }
    var[id].code = NULL;
    var[id].alias = desc_famille[i].nom;
    var[id].genre = G_SAISIE;
    var[id].domaine = D_FAMILLE;
    var[id].type = convert_type(desc_famille[i].type_donnee);
    var[id].nature = convert_nature(desc_famille[i].nat_code);
    var[id].classe = desc_famille[i].classe;
    var[id].cat_tl = desc_famille[i].categorie_TL;
    var[id].cot_soc = -1;
    var[id].ind_abat = false;
    var[id].rap_cat = -1;
    var[id].sanction = -1;
    var[id].cat_1731b = -1;
    var[id].indice_tab = -1;
    var[id].acompte = false;
    var[id].avfisc = -1;
    var[id].restituee = false;
    var[id].desc = (T_desc_var *)&desc_famille[i];
    add_var_to_index(var[id].alias, &var[id]);
  }

  //printf("Chargement des variables revenu\n");
  for (size_t i = 0; i < NB_REVENU; ++i) {
    size_t id = desc_revenu[i].indice & INDICE_VAL;
    if (var[id].desc != NULL) {
      fprintf(stderr,
              "Variable saisie (revenu) à l'indice %ld existe déjà (%s/%s)\n",
              id, var[id].code, desc_revenu[i].nom);
      exit(1);
    }
    var[id].code = NULL;
    var[id].alias = desc_revenu[i].nom;
    var[id].genre = G_SAISIE;
    var[id].domaine = D_REVENU;
    var[id].type = convert_type(desc_revenu[i].type_donnee);
    var[id].nature = convert_nature(desc_revenu[i].nat_code);
    var[id].classe = desc_revenu[i].classe;
    var[id].cat_tl = desc_revenu[i].categorie_TL;
    var[id].cot_soc = desc_revenu[i].cotsoc;
    var[id].ind_abat = desc_revenu[i].ind_abat != 0;
    var[id].rap_cat = desc_revenu[i].rapcat;
    var[id].sanction = desc_revenu[i].sanction;
    var[id].cat_1731b = -1;
    var[id].indice_tab = -1;
    var[id].acompte = desc_revenu[i].acompte != 0;
    var[id].avfisc = desc_revenu[i].avfisc;
    var[id].restituee = false;
    var[id].desc = (T_desc_var *)&desc_revenu[i];
    add_var_to_index(var[id].alias, &var[id]);
  }

  //printf("Chargement des variables revcor\n");
  for (size_t i = 0; i < NB_REVENU_CORREC; ++i) {
    size_t id = desc_revenu_correc[i].indice & INDICE_VAL;
    if (var[id].desc != NULL) {
      fprintf(stderr,
              "Variable saisie (revcor) à l'indice %ld existe déjà (%s/%s)\n",
              id, var[id].code, desc_revenu_correc[i].nom);
      exit(1);
    }
    var[id].code = NULL;
    var[id].alias = desc_revenu_correc[i].nom;
    var[id].genre = G_SAISIE;
    var[id].domaine = D_REVENU_CORR;
    var[id].type = convert_type(desc_revenu_correc[i].type_donnee);
    var[id].nature = convert_nature(desc_revenu_correc[i].nat_code);
    var[id].classe = desc_revenu_correc[i].classe;
    var[id].cat_tl = desc_revenu_correc[i].categorie_TL;
    var[id].cot_soc = desc_revenu_correc[i].cotsoc;
    var[id].ind_abat = desc_revenu_correc[i].ind_abat != 0;
    var[id].rap_cat = desc_revenu_correc[i].rapcat;
    var[id].sanction = desc_revenu_correc[i].sanction;
    var[id].cat_1731b = -1;
    var[id].indice_tab = -1;
    var[id].acompte = desc_revenu_correc[i].acompte != 0;
    var[id].avfisc = desc_revenu_correc[i].avfisc;
    var[id].restituee = false;
    var[id].desc = (T_desc_var *)&desc_revenu_correc[i];
    add_var_to_index(var[id].alias, &var[id]);
  }

  //printf("Chargement des variables variation\n");
  for (size_t i = 0; i < NB_VARIATION; ++i) {
    size_t id = desc_variation[i].indice & INDICE_VAL;
    if (var[id].desc != NULL) {
      fprintf(stderr,
              "Variable saisie (revenucor) à l'indice %ld existe déjà (%s/%s)\n",
              id, var[id].code, desc_variation[i].nom);
      exit(1);
    }
    var[id].code = NULL;
    var[id].alias = desc_variation[i].nom;
    var[id].genre = G_SAISIE;
    var[id].domaine = D_VARIATION;
    var[id].type = convert_type(desc_variation[i].type_donnee);
    var[id].nature = convert_nature(-1); // does not exist fot this domain
    var[id].classe = desc_variation[i].classe;
    var[id].cat_tl = -1;
    var[id].cot_soc = -1;
    var[id].ind_abat = -1;
    var[id].rap_cat = -1;
    var[id].sanction = -1;
    var[id].cat_1731b = -1;
    var[id].indice_tab = -1;
    var[id].acompte = false;
    var[id].avfisc = -1;
    var[id].restituee = false;
    var[id].desc = (T_desc_var *)&desc_variation[i];
    add_var_to_index(var[id].alias, &var[id]);
  }

  //printf("Chargement des variables penalite\n");
  for (size_t i = 0; i < NB_PENALITE; ++i) {
    size_t id = desc_penalite[i].indice & INDICE_VAL;
    if (var[id].desc != NULL) {
      fprintf(stderr,
              "Variable saisie (revenucor) à l'indice %ld existe déjà (%s/%s)\n",
              id, var[id].code, desc_penalite[i].nom);
      exit(1);
    }
    var[id].code = NULL;
    var[id].alias = desc_penalite[i].nom;
    var[id].genre = G_SAISIE;
    var[id].domaine = D_PENALITE;
    var[id].type = convert_type(desc_penalite[i].type_donnee);
    var[id].nature = convert_nature(-1); // N'existe pas pour ce domaine
    var[id].classe = -1;
    var[id].cat_tl = -1;
    var[id].cot_soc = -1;
    var[id].ind_abat = -1;
    var[id].rap_cat = -1;
    var[id].sanction = -1;
    var[id].cat_1731b = -1;
    var[id].indice_tab = -1;
    var[id].acompte = false;
    var[id].avfisc = -1;
    var[id].restituee = false;
    var[id].desc = (T_desc_var *)&desc_penalite[i];
    add_var_to_index(var[id].alias, &var[id]);
  }

  //printf("Chargement des variables calculée/base\n");
  for (size_t i = 0; i < NB_DEBUG01; ++i) {
    genre_t genre = convert_genre(desc_debug01[i].indice);
    size_t id = desc_debug01[i].indice & INDICE_VAL;
    if (genre == G_CALCULEE) id += TAILLE_SAISIE;
    else if (genre == G_BASE) id += TAILLE_SAISIE + TAILLE_CALCULEE;
    if (genre == G_SAISIE) {
      if (var[id].desc == NULL) {
        fprintf(stderr,
                "Variable saisie à l'indice %ld sans définition (%s)\n",
                id, desc_debug01[i].nom);
        exit(1);
      }
      if (var[id].alias == NULL) {
        fprintf(stderr,
                "Variable saisie à l'indice %ld sans alias (%s)\n",
                id, desc_debug01[i].nom);
        exit(1);
      }
      if (strcmp(var[id].alias, desc_debug01[i].nom) != 0) {
        var[id].code = desc_debug01[i].nom;
        add_var_to_index(var[id].code, &var[id]);
      }
    } else {
      if (var[id].desc != NULL) {
        fprintf(stderr,
                "Variable base/calculée à l'indice %ld existe déjà (%s/%s)\n",
                id, var[id].code, desc_debug01[i].nom);
        exit(1);
      }
      var[id].code = desc_debug01[i].nom;
      var[id].alias = NULL;
      var[id].genre = genre;
      var[id].domaine = D_INDEFINI;
      var[id].type = convert_type(desc_debug01[i].type_donnee);
      var[id].nature = convert_nature(desc_debug01[i].nat_code);
      var[id].classe = desc_debug01[i].classe;
      var[id].cat_tl = desc_debug01[i].categorie_TL;
      var[id].cot_soc = desc_debug01[i].cotsoc;
      var[id].ind_abat = desc_debug01[i].ind_abat != 0;
      var[id].rap_cat = desc_debug01[i].rapcat;
      var[id].sanction = desc_debug01[i].sanction;
      var[id].cat_1731b = -1;
      var[id].indice_tab = -1;
      var[id].acompte = false;
      var[id].avfisc = -1;
      var[id].restituee = false;
      var[id].desc = (T_desc_var *)&desc_debug01[i];
      add_var_to_index(var[id].code, &var[id]);
    }
  }

  //printf("Chargement des variables restituées\n");
  for (size_t i = 0; i < NB_RESTITUEE; ++i) {
    genre_t genre = convert_genre(desc_restituee[i].indice);
    size_t id = desc_restituee[i].indice & INDICE_VAL;
    if (genre == G_CALCULEE) id += TAILLE_SAISIE;
    else if (genre == G_BASE) id += TAILLE_SAISIE + TAILLE_CALCULEE;
    if (var[id].desc == NULL) {
      fprintf(stderr,
              "Variable restituée à l'indice %ld sans définition (%s)\n",
              id, desc_restituee[i].nom);
      exit(1);
    }
    var[id].restituee = true;
  }

  //printf("Ajustement des tableaux\n");
  size_t i = 0;
  while (i < TAILLE_TOTALE) {
    size_t j = i + 1;
    while ((j < TAILLE_TOTALE) && (var[j].code == NULL)) {
      memcpy(&var[j], &var[i], sizeof(var_t));
      var[j].indice_tab = (j - i);
      ++j;
    }
    if ((j - i) > 1) {
      var[i].indice_tab = 0;
      //printf("Tableau %s de taille %ld (indices %ld-%ld)\n", var[i].code, (j - i), i, j - 1);
    }
    i = j;
  }

  //printf("Chargement des variables terminé\n");

  sort_index();
}

static var_t *
cherche_var(
  const char *code)
{
  var_entry_t var_entry;
  int res = -1, inf = 0, sup = var_index_entries, millieu;
  while ((res != 0) && (inf < sup)) {
    millieu = (inf + sup) / 2;
    var_entry = var_index[millieu];
    res = strcmp(code, var_entry.code);
    if (res < 0) sup = millieu;
    else if (res > 0) inf = millieu + 1;
  }
  if (res == 0)
    return var_entry.var;
  else
    return NULL;

  return NULL;
}

CAMLprim value
ml_charge_vars(void)
{
  CAMLparam0();
  CAMLlocal4(mlListTemp, mlListOut, mlTemp, mlTemp2);

  init_var_dict();

  mlListOut = Val_emptylist;
  size_t nb_vars = sizeof(var) / ((void *)(var + 1) - (void *)var);
  for (size_t i = 0; i < nb_vars; ++i) {
    if (var[i].code == NULL) {
      fprintf(stderr, "Code indéfini indice %ld\n", i);
      exit(1);
    } else {
      mlTemp = caml_alloc_tuple(16);
      Store_field(mlTemp, 0, caml_copy_string(var[i].code));
      if (var[i].alias == NULL) mlTemp2 = Val_none;
      else mlTemp2 = caml_alloc_some(caml_copy_string(var[i].alias));
      Store_field(mlTemp, 1, mlTemp2);
      Store_field(mlTemp, 2, Val_int(var[i].genre));
      Store_field(mlTemp, 3, Val_int(var[i].domaine));
      Store_field(mlTemp, 4, Val_int(var[i].type));
      Store_field(mlTemp, 5, Val_int(var[i].nature));
      Store_field(mlTemp, 6, Val_int(var[i].classe));
      Store_field(mlTemp, 7, Val_int(var[i].cat_tl));
      Store_field(mlTemp, 8, Val_int(var[i].cot_soc));
      Store_field(mlTemp, 9, Val_bool(var[i].ind_abat));
      Store_field(mlTemp, 10, Val_int(var[i].rap_cat));
      Store_field(mlTemp, 11, Val_int(var[i].sanction));
      Store_field(mlTemp, 12, Val_int(var[i].indice_tab));
      Store_field(mlTemp, 13, Val_bool(var[i].acompte));
      Store_field(mlTemp, 14, Val_int(var[i].avfisc));
      Store_field(mlTemp, 15, Val_bool(var[i].restituee));
      mlListTemp = caml_alloc_small(2, Tag_cons);
      Field(mlListTemp, 0) = mlTemp;
      Field(mlListTemp, 1) = mlListOut;
      mlListOut = mlListTemp;
    }
  }

  CAMLreturn(mlListOut);
}

static CAMLprim value
convert_tgv_to_c(
  value mlTGVList)
{
  CAMLparam1(mlTGVList);
  CAMLlocal1(mlTGVListTemp);

  mlTGVListTemp = mlTGVList;
  while (mlTGVListTemp != Val_emptylist) {
    const char *code = String_val(Field(Field(mlTGVListTemp, 0), 0));
    int id = Int_val(Field(Field(mlTGVListTemp, 0), 1));
    double montant = Double_val(Field(Field(mlTGVListTemp, 0), 2));
    var_t *var = cherche_var(code);
    if (var == NULL) {
      fprintf(stderr, "La variable %s n'existe pas (alias ?)\n", code);
      exit(1);
    }
    if (id < 0) {
      IRDATA_range_base(tgv, var->desc, montant);
    } else {
      IRDATA_range_tableau(tgv, var->desc, id, montant);
    }
    mlTGVListTemp = Field(mlTGVListTemp, 1);
  }

  CAMLreturn(Val_unit);
}

static CAMLprim value
convert_tgv_to_ml(
  void)
{
  CAMLparam0();
  CAMLlocal3(mlTGVListOut, mlTGVListTemp, mlTemp);

  mlTGVListOut = Val_emptylist;
  size_t nb_vars = sizeof(var) / ((void *)(var + 1) - (void *)var);
  for (size_t i = 0; i < nb_vars; ++i) {
    if (var[i].code != NULL) {
      double *montant = NULL;
      if (var[i].indice_tab < 0) {
        montant = IRDATA_extrait_special(tgv, var[i].desc);
      } else {
        montant = IRDATA_extrait_tableau(tgv, var[i].desc, var[i].indice_tab);
      }
      if (montant != NULL) {
        mlTemp = caml_alloc_tuple(3);
        Store_field(mlTemp, 0, caml_copy_string(var[i].code));
        Store_field(mlTemp, 1, Val_int(var[i].indice_tab));
        Store_field(mlTemp, 2, caml_copy_double(*montant));
        mlTGVListTemp = caml_alloc_small(2, Tag_cons);
        Field(mlTGVListTemp, 0) = mlTemp;
        Field(mlTGVListTemp, 1) = mlTGVListOut;
        mlTGVListOut = mlTGVListTemp;
      }
    } else {
      fprintf(stderr, "Code indéfini indice %ld\n", i);
      exit(1);
    }
  }

  CAMLreturn(mlTGVListOut);
}

CAMLprim value
ml_exec_ench(
  value mlEnch,
  value mlTGVList)
{
  CAMLparam2(mlEnch, mlTGVList);
  CAMLlocal2(mlTGVListOut, mlTemp);

  init_var_dict();
  if (tgv == NULL) {
    tgv = IRDATA_new_irdata();
  } else {
    IRDATA_reset_irdata(tgv);
  }

  const char *ench = String_val(mlEnch);

  mlTemp = convert_tgv_to_c(mlTGVList);

  size_t nb_ench = sizeof(enchaineurs) / ((void *)(enchaineurs + 1) - (void *)enchaineurs);
  size_t i = 0;
  while (i < nb_ench) {
    if (strcmp(ench, enchaineurs[i].name) == 0)
      break;
    ++i;
  }
  if (i >= nb_ench) {
      fprintf(stderr, "L'enchaineur %s n'existe pas\n", ench);
      exit(1);
  }

  enchaineurs[i].function(tgv);

  mlTGVListOut = convert_tgv_to_ml();

  CAMLreturn(mlTGVListOut);
}

CAMLprim value
ml_exec_verif(
  value mlVerif,
  value mlTGVList)
{
  CAMLparam2(mlVerif, mlTGVList);
  CAMLlocal2(mlTGVListOut, mlTemp);

  init_var_dict();
  if (tgv == NULL) {
    tgv = IRDATA_new_irdata();
  } else {
    IRDATA_reset_irdata(tgv);
  }

  const char *verif = String_val(mlVerif);

  mlTemp = convert_tgv_to_c(mlTGVList);

  size_t nb_verif = sizeof(verifications) / ((void *)(verifications + 1) - (void *)verifications);
  size_t i = 0;
  while (i < nb_verif) {
    if (strcmp(verif, verifications[i].name) == 0)
      break;
    ++i;
  }
  if (i >= nb_verif) {
      fprintf(stderr, "La verification %s n'existe pas\n", verif);
      exit(1);
  }

  struct S_discord * erreurs = verifications[i].function(tgv);

  mlTGVListOut = convert_tgv_to_ml();

// TODO: renvoyer les erreurs
  CAMLreturn(mlTGVListOut);
}

CAMLprim value
ml_annee_calc(void)
{
  CAMLparam0();
  CAMLreturn(Val_int(ANNEE_REVENU));
}
