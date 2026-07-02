.onLoad = function(libname, pkgname) {
    S7::methods_register()
    register_kw_tidy_methods()
}
