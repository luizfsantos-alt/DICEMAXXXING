extends GutTest
## Comparação de versões do aviso de atualização (engine/app_version.gd).


func test_parse_basico():
	assert_eq(AppVersion.parse("1.2.3").nums, [1, 2, 3])
	assert_eq(AppVersion.parse("v0.4.0").nums, [0, 4, 0], "prefixo v da tag")
	assert_eq(AppVersion.parse(" V2 ").nums, [2])
	assert_eq(AppVersion.parse("1.0.0-beta.2").pre, "beta.2")
	assert_eq(AppVersion.parse("1.0.0+57").nums, [1, 0, 0], "metadado de build ignorado")


func test_parse_invalido():
	for s in ["", "v", "abc", "1..2", "1.x", "1.2.-3", "-beta"]:
		assert_true(AppVersion.parse(s).is_empty(), s)


func test_mais_nova_por_componente():
	assert_true(AppVersion.is_newer("0.4.0", "0.3.0"))
	assert_true(AppVersion.is_newer("1.0.0", "0.9.9"))
	assert_true(AppVersion.is_newer("0.3.1", "0.3.0"))
	assert_true(AppVersion.is_newer("v0.10.0", "0.9.0"), "número, não texto")
	assert_false(AppVersion.is_newer("0.3.0", "0.4.0"))
	assert_false(AppVersion.is_newer("0.9.9", "1.0.0"))


func test_igual_nao_e_mais_nova():
	assert_false(AppVersion.is_newer("0.3.0", "0.3.0"))
	assert_false(AppVersion.is_newer("v0.3.0", "0.3.0"))
	assert_false(AppVersion.is_newer("1.0", "1.0.0"), "zeros à direita")
	assert_false(AppVersion.is_newer("1.0.0", "1"))


func test_tamanhos_diferentes():
	assert_true(AppVersion.is_newer("1.0.1", "1.0"))
	assert_false(AppVersion.is_newer("1.0", "1.0.1"))


func test_pre_versao():
	assert_true(AppVersion.is_newer("1.0.0", "1.0.0-beta"), "final ganha da beta")
	assert_false(AppVersion.is_newer("1.0.0-beta", "1.0.0"))
	assert_true(AppVersion.is_newer("1.0.1-beta", "1.0.0"))
	assert_false(AppVersion.is_newer("1.0.0-rc", "1.0.0-beta"), "sufixos iguais em número: sem aviso")


func test_invalida_nunca_avisa():
	assert_false(AppVersion.is_newer("lixo", "0.3.0"))
	assert_false(AppVersion.is_newer("1.0.0", ""))
	assert_false(AppVersion.is_newer("", ""))


func test_release_pega_o_apk():
	var info := AppVersion.from_release({
		"tag_name": "v0.4.0",
		"html_url": "https://github.com/x/y/releases/tag/v0.4.0",
		"assets": [
			{"name": "notas.txt", "browser_download_url": "https://github.com/x/y/notas.txt"},
			{"name": "dicemaxxing.apk", "browser_download_url": "https://github.com/x/y/dicemaxxing.apk"},
		],
	})
	assert_eq(info.version, "0.4.0")
	assert_eq(info.url, "https://github.com/x/y/dicemaxxing.apk")


func test_release_sem_apk_abre_a_pagina():
	var info := AppVersion.from_release({"tag_name": "v0.4.0", "html_url": "https://github.com/x/y/releases/tag/v0.4.0", "assets": []})
	assert_eq(info.url, "https://github.com/x/y/releases/tag/v0.4.0")


func test_resposta_ruim_e_ignorada():
	assert_eq(AppVersion.from_release(null), {})
	assert_eq(AppVersion.from_release([]), {})
	assert_eq(AppVersion.from_release({"message": "Not Found"}), {})
	assert_eq(AppVersion.from_release({"tag_name": "apk-main", "html_url": "https://github.com/x"}), {})
	assert_eq(AppVersion.from_release({"tag_name": "v1.0.0", "html_url": "http://inseguro"}), {})


func test_menu_mostra_aviso():
	var m := MenuScreen.new().setup()
	add_child_autofree(m)
	assert_null(m.update_bar)
	m.show_update({"version": "9.9.9", "url": "https://github.com/x/y/dicemaxxing.apk"})
	assert_not_null(m.update_bar)
	assert_eq(m.update_url, "https://github.com/x/y/dicemaxxing.apk")
