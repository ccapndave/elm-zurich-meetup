var
  gulp = require('gulp'),
  tsify = require('tsify'),
  browserify = require('browserify'),
  watchify = require('watchify'),
  elm = require('gulp-elm'),
  less = require('gulp-less'),
  postcss = require('gulp-postcss'),
  autoprefixer = require('autoprefixer'),
  concatCss = require('gulp-concat-css'),
  sourcemaps = require('gulp-sourcemaps'),
  gls = require('gulp-live-server'),
  notify = require('gulp-notify'),
  source = require('vinyl-source-stream'),
  _ = require('lodash');

var server,
  appDir = 'app',
  srcDir = appDir + '/elm',
  jsDir = appDir + '/js',
  styleDir = appDir + '/style',
  buildDir = 'build',
  appEntry = jsDir + '/app.ts';

// The array of assets to copy directly into the build
var assetGlobs = [
  appDir + "/**/*",
  "!" + srcDir, "!" + srcDir + "/**/*",
  "!" + styleDir, "!" + styleDir + "/**/*"
];

// Elm tasks
gulp.task('make', () => {
  var stream = gulp.src(srcDir + '/**/Main.elm')
    .pipe(elm.bundle("Main.js"))
    .on('error', notify.onError("<" + "%= error.message %>"))
    .pipe(gulp.dest(buildDir + '/js'))
    .pipe(notify('Elm built'));

  // Trigger live reload if the client server is running
  if (server) stream.pipe(server.notify());

  return stream;
});

gulp.task('make:watch', ['make'], () => {
  gulp.watch([appDir + "/**/*.elm", "elm-package.json"], ['make']);
});

// Typescript tasks
gulp.task('watchify', false, () => {
  function getBrowserifyBundler(entry, useSourceMaps, useWatchify) {
    var params = useWatchify ? _.assign({ debug: useSourceMaps }, watchify.args) : { debug: useSourceMaps };
    var wrapper = useWatchify ? _.flowRight(watchify, browserify) : browserify;
    params = _.assign(params, {});

    return wrapper(params).add(require.resolve("./" + entry));
  }

  function getRebundler(bundleFile, bundle) {
    bundle = bundle
      .plugin('tsify')
      .transform("babelify", {
        presets: ["es2015"],
        extensions: [".ts", ".js"]
      });

    // The bundling process
    var rebundle = () => {
      var start = Date.now();
      var stream = bundle
        .bundle()
        .on("error", notify.onError("<%= error.message %>"))
        .pipe(source(bundleFile))
        .pipe(gulp.dest(buildDir));

      // Trigger live reload if the client server is running
      if (server) {
        stream
          .pipe(notify('Built in ' + (Date.now() - start) + 'ms'))
          .pipe(server.notify());
      }

      return stream;
    };

    return rebundle;
  }

  const bundle = getBrowserifyBundler(appEntry, true, true), rebundle = getRebundler("js/bundle.js", bundle);
  bundle.on('update', rebundle);
  return rebundle();
});

// Less tasks
gulp.task('less', () => {
  const stream = gulp.src([styleDir + '/app.less'])
    .pipe(sourcemaps.init())
    .pipe(less())
    .on("error", notify.onError("<" + "%= error.message %>"))
    .pipe(postcss([autoprefixer({ map: true, browsers: ['last 2 version'] })]))
    .pipe(concatCss("bundle.css"))
    .pipe(sourcemaps.write('.'))
    .pipe(gulp.dest(buildDir + "/css"));

  // Trigger live reload if the client server is running
  if (server) stream.pipe(server.notify.apply(server));

  return stream;
});

gulp.task('less:watch', ['less'], () => {
  gulp.watch([styleDir + '/**/*.less'], ['less']);
});

// Asset tasks
gulp.task('copy-assets', function () {
  // Copy everything apart from the src and style folders into the client build folder
  gulp.src(assetGlobs)
    .pipe(gulp.dest(buildDir));
});

gulp.task('copy-assets:watch', ['copy-assets'], () => {
    gulp.watch(assetGlobs, ['copy-assets']);
});

// Server tasks
gulp.task('server:start', () => {
  server = gls.new(appDir + '/server.js');
  server.start();
});

gulp.task('server:restart', () => {
  if (server) {
    server.stop().then(() => server.start());
  }
});

gulp.task('server:watch', ['server:start'], () => {
  gulp.watch(appDir + '/server.js', ['server:restart']);
});

/** Development tasks */
gulp.task('default',
  ['watchify', 'make:watch', 'less:watch', 'copy-assets:watch', 'server:watch']
);
