import urllib3
from purestorage import FlashArray
import argparse

urllib3.disable_warnings()

array = FlashArray("10.21.214.13", "pureuser", "pureuser")
array_info = array.get()
print("FlashArray {} (version {}) REST session established!".format(array_info['array_name'], 
    array_info['version']))

def main():
    parser = argparse.ArgumentParser(add_help=True)
    parser.add_argument('--source', help="Source volume", default=None)
    parser.add_argument('--backup', help="Backup NFS volume", default=None)
    parser.add_argument('--target', help="Target volume", default=None)
    parser.add_argument('--overwrite', help="Overwrite on copy", action='store_true',      
                    default=False)
    parser.add_argument('--copy', help="Copy volume", action='store_true', default=False)
    parser.add_argument('--snapshot', help="Take snapshot", action='store_true', default=False)
    parser.add_argument('--restore', help="Restore snapshot", action='store_true', default=False)
    parser.add_argument('--list', help="List volumes", action='store_true', default=False)
    try:
        options = parser.parse_args()
    except Exception as e:
        parser.print_help()
        sys.exit(1)
    if options.list:
        print("\nListing volumes:")
        for v in array.list_volumes():
            if v['name'].startswith('p4'):
                print(v['name'])
        print("\nsnapshots:")
        snapshots = [v for v in array.list_volumes(snap=True)]
        for s in snapshots:
            print(s)
        print("\nsnapshots  transfer {}:".format(options.backup))
        snapshots = [v for v in array.list_volumes(snap=True, transfer=True)]
        for s in snapshots:
            print(s)
        if options.backup:
            print("\nsnapshots on {}:".format(options.backup))
            snapshots = [v for v in array.list_volumes(snap=True, on=options.backup)]
            for s in snapshots:
                print(s)
    if options.copy:
        print("Copying {} to {}, overwrite {}".format(
            options.source, options.target, options.overwrite))
        print(array.copy_volume(options.source, options.target, overwrite=options.overwrite))
    if options.restore:
        print("Restoring {} from {}, snap=True".format(
            options.source, options.backup))
        print("cmd: array.create_snapshot({}, snap=True, on={})".format(
            options.source, options.backup))
        print(array.create_snapshot(options.source, snap=True, on=options.backup))
    if options.snapshot:
        print(array.create_pgroup_snapshot(options.source, replicate_now=True))


if __name__ == '__main__':
    main()

