allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Workarounds for Flutter plugins (e.g. isar_flutter_libs 3.1.0+1) built
// against older AGP/SDK that fail to compile under AGP 8+:
//   1. Missing `android.namespace` (AGP 8 requirement) — must be set BEFORE
//      AGP creates variant builders, so we hook into plugin application via
//      plugins.withId instead of afterEvaluate. afterEvaluate runs too late
//      for `assembleRelease`, which eagerly resolves variants.
//   2. compileSdk < 31, which breaks AppCompat resource linking (`lStar` etc.)
fun setNamespaceIfMissing(project: Project) {
    val androidExt = project.extensions.findByName("android") ?: return
    val cls = androidExt.javaClass
    val getNamespace = cls.methods.firstOrNull { it.name == "getNamespace" && it.parameterCount == 0 }
    val setNamespace = cls.methods.firstOrNull { it.name == "setNamespace" && it.parameterCount == 1 }
    if (getNamespace != null && setNamespace != null && getNamespace.invoke(androidExt) == null) {
        val fallback = project.group.toString().ifBlank { "flutter.plugin.${project.name}" }
        setNamespace.invoke(androidExt, fallback)
    }
}

subprojects {
    plugins.withId("com.android.library") { setNamespaceIfMissing(project) }
    plugins.withId("com.android.application") { setNamespaceIfMissing(project) }

    afterEvaluate {
        val androidExt = project.extensions.findByName("android") ?: return@afterEvaluate
        val cls = androidExt.javaClass

        // Defensive re-check in case namespace was cleared after plugin apply.
        setNamespaceIfMissing(project)

        val getCompileSdk = cls.methods.firstOrNull { it.name == "getCompileSdkVersion" && it.parameterCount == 0 }
        val setCompileSdk = cls.methods.firstOrNull {
            it.name == "setCompileSdkVersion" && it.parameterCount == 1 && it.parameterTypes[0] == String::class.java
        }
        val current = getCompileSdk?.invoke(androidExt) as? String
        if (current != null && current.startsWith("android-")) {
            val ver = current.removePrefix("android-").toIntOrNull()
            if (ver != null && ver < 34 && setCompileSdk != null) {
                setCompileSdk.invoke(androidExt, "android-34")
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
