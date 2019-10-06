import apt_pkg

holds = ['PreDepends', 'Depends', 'Recommends']
pkgs = set()
keeps = set()
virtuals = {}

apt_pkg.init()
cache = apt_pkg.Cache()
dep_cache = apt_pkg.DepCache(cache)


def flag_provides(virtual, pkg):
    if pkg.current_ver:
        if virtual not in virtuals:
            virtuals[virtual] = set()
        virtuals[virtual].add(pkg.name)


def hold_pkg(pkg):
    if pkg.name in keeps:
        return

    if pkg.current_ver:
        keeps.add(pkg.name)
        hold_dependencies(pkg.current_ver.depends_list)

    if pkg.provides_list:
        flag_provides(pkg.name, pkg)
        hold_provides(pkg.provides_list)


def hold_provides(provides_list):
    for provides in provides_list:
        flag_provides(provides[0], provides[2].parent_pkg)
        hold_pkg(provides[2].parent_pkg)


def hold_dependencies(dep_dict):
    for dep_type, deps in dep_dict.items():
        if dep_type in holds:
            for dep in deps:
                for opt in dep:
                    hold_pkg(opt.target_pkg)


def check_pkg(pkg):
    if not pkg.current_ver:
        return

    pkgs.add(pkg.name)

    if pkg.name in keeps:
        return

    if dep_cache.is_auto_installed(pkg):
        return

    keeps.add(pkg.name)
    hold_dependencies(pkg.current_ver.depends_list)



for pkg in cache.packages:
    check_pkg(pkg)

print "\nHeld packages:"
keeps = list(keeps)
keeps.sort()
print '\n'.join(keeps)

print "\nOrphaned packages:"
orphans = list(pkgs.difference(keeps))
orphans.sort()
print '\n'.join(orphans)

print "\nVirtual packages provided by multiple held packages:"
keys = virtuals.keys()
keys.sort()
for key in keys:
    if len(virtuals[key]) > 1:
        vals = list(virtuals[key])
        vals.sort()
        print '%s:\n\t%s' % (key, '\n\t'.join(vals))

print '\n%d packages held' % len(keeps)
print '%d packages orphaned' % len(orphans)

print "\nTo remove orphans (omit '-s' option to do this for real):"
print 'apt-get -s purge %s' % ' '.join(orphans)
print 'aptitude -s purge %s' % ' '.join(orphans)
